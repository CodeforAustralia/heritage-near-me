CREATE TABLE IF NOT EXISTS story (
	id SERIAL PRIMARY KEY,
	title TEXT,
	blurb TEXT,
	story TEXT,
	author TEXT,
	dateStart DATE,
	dateEnd DATE,
	published BOOLEAN
);

CREATE TABLE IF NOT EXISTS photo (
	id SERIAL PRIMARY KEY,
	photo TEXT
);

CREATE TABLE IF NOT EXISTS story_photo (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	photo_id SERIAL REFERENCES photo (id)
);

CREATE TABLE IF NOT EXISTS site (
	id SERIAL PRIMARY KEY,
	heritageItemId SERIAL,
	name TEXT,
	suburb TEXT,
	latitude TEXT,
	longitude TEXT
);

CREATE TABLE IF NOT EXISTS story_site (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	site_id SERIAL REFERENCES site (id)
);

CREATE TABLE IF NOT EXISTS link (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	url TEXT,
	label TEXT
);

CREATE TABLE IF NOT EXISTS favourites (
	id SERIAL PRIMARY KEY,
	datetime TIMESTAMP WITHOUT TIME ZONE,
	story_id SERIAL REFERENCES story (id),
	favourited BOOLEAN
);

CREATE TABLE IF NOT EXISTS views (
	id SERIAL PRIMARY KEY,
	datetime TIMESTAMP WITHOUT TIME ZONE,
	story_id SERIAL REFERENCES story (id)
);

CREATE SCHEMA hnm
	CREATE VIEW story_discover AS
		SELECT DISTINCT ON (story.id)
			story.id, story.title, story.blurb, photo.photo
		FROM story
		LEFT JOIN story_photo ON story_photo.story_id = story.id
		LEFT JOIN photo       ON story_photo.photo_id = photo.id
		WHERE story.published

	CREATE VIEW story_details AS
		SELECT
			story.id, story.title, story.blurb, story.story, story.author,
			min(site.suburb) AS suburb,
			json_agg(photo.photo) AS photos,
			json_object('{start, end}', ARRAY[to_char(story.dateStart, 'YYYY-MM-DD'), to_char(story.dateEnd, 'YYYY-MM-DD')]) AS dates,
			json_agg(DISTINCT json_object('{id, name}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name])::jsonb) AS sites,
			json_agg(DISTINCT json_object('{lat, lng}', ARRAY[site.latitude, site.longitude])::jsonb) AS locations,
			CASE WHEN COUNT(link.id) = 0 THEN
				'[]'
			ELSE
				json_agg(DISTINCT json_object('{url, label}', ARRAY[link.url, link.label])::jsonb)
			END AS links
		FROM story
		LEFT JOIN story_photo ON story_photo.story_id = story.id
		LEFT JOIN photo       ON story_photo.photo_id = photo.id
		LEFT JOIN story_site  ON story_site.story_id  = story.id
		LEFT JOIN site        ON story_site.site_id   = site.id
		LEFT JOIN link        ON link.story_id        = site.id
		WHERE story.published
		GROUP BY story.id

	CREATE VIEW favourite_stats AS
		SELECT
			story_id,
			SUM(CASE WHEN favourited IS NOT null THEN 1 ELSE 0 END) AS total_choices,
			SUM(CASE WHEN favourited = true THEN 1 ELSE 0 END) AS favourites,
			SUM(CASE WHEN favourited = false THEN 1 ELSE 0 END) AS passes
		FROM favourites
		GROUP BY story_id

	CREATE VIEW view_stats AS
		SELECT
			story_id,
			SUM(CASE WHEN views.id IS NOT null THEN 1 ELSE 0 END) AS views
		FROM views
		GROUP BY story_id

	CREATE VIEW stats AS
		SELECT
			story.id, story.title,
			total_choices, favourites, passes,
			views
		FROM story
		LEFT JOIN favourite_stats ON favourite_stats.story_id = story.id
		LEFT JOIN view_stats      ON view_stats.story_id      = story.id
		WHERE story.published
;

	CREATE VIEW hnm.story AS SELECT * FROM story WHERE published;
	CREATE VIEW hnm.story_site AS SELECT * FROM story_site;
	CREATE VIEW hnm.story_photo AS SELECT * FROM story_photo;

	CREATE VIEW hnm.favourites AS SELECT * FROM favourites;
	CREATE VIEW hnm.views AS SELECT * FROM views;

CREATE OR REPLACE FUNCTION hnm.nearby_stories(lat TEXT, lng TEXT)
	RETURNS TABLE (
		id INTEGER,
		title TEXT,
		blurb TEXT,
		photo TEXT,
		distance FLOAT
	) AS
$$
BEGIN
	RETURN QUERY
	SELECT
		story.id, story.title, story.blurb,
		MIN(photo.photo),
		MIN(ST_Distance_Sphere(
			ST_GeomFromText('POINT('||site.longitude||' '||site.latitude||')'),
			ST_GeomFromText('POINT('||$2||' '||$1||')')
		)) AS distance
	FROM story
	LEFT JOIN story_photo ON story_photo.story_id = story.id
	LEFT JOIN photo       ON story_photo.photo_id = photo.id
	LEFT JOIN story_site  ON story_site.story_id  = story.id
	LEFT JOIN site        ON story_site.site_id   = site.id
	WHERE story.published
	GROUP BY story.id
	ORDER BY distance ASC;
END;
$$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE FUNCTION hnm.update_stories(stories JSON)
	RETURNS TABLE (
		story_id INTEGER,
		title TEXT,
		blurb TEXT,
		story TEXT,
		date_start DATE,
		date_end DATE,
		published BOOLEAN
	) AS
$$
BEGIN
	RETURN QUERY
	WITH

	new AS (SELECT
			NULLIF(new.id, '')::INTEGER AS id,
			new.title AS title,
			REPLACE(new.blurb, '\n', E'\n') AS blurb,
			REPLACE(new.story, '\n', E'\n') AS story,
			CASE WHEN NULLIF(new.date_start, '') IS NULL THEN NULL ELSE to_date(new.date_start, 'yyyy') END AS date_start,
			CASE WHEN NULLIF(new.date_end, '') IS NULL THEN NULL ELSE to_date(new.date_end, 'yyyy') END AS date_end,
			COALESCE(NULLIF(new.published, '')::BOOLEAN, FALSE) AS published
		FROM json_to_recordset(stories)
		AS new(
			id TEXT,
			title TEXT,
			blurb TEXT,
			story TEXT,
			date_start TEXT,
			date_end TEXT,
			published TEXT
		)
	),

	inserted AS (INSERT INTO story (title, blurb, story, dateStart, dateEnd, published) (
		SELECT
			new.title, new.blurb, new.story, new.date_start, new.date_end, new.published
		FROM new
		WHERE new.id IS NULL
	) RETURNING *),

	updated AS (INSERT INTO story (id, title, blurb, story, dateStart, dateEnd, published) (
		SELECT new.*
		FROM new
		WHERE new.id IS NOT NULL
	)
	ON CONFLICT (id) DO UPDATE SET
		title = excluded.title,
		blurb = excluded.blurb,
		story = excluded.story,
		dateStart = excluded.dateStart,
		dateEnd = excluded.dateEnd,
		published = excluded.published
	RETURNING *),

	results AS (SELECT
			COALESCE(inserted.id, updated.id, new.id),
			COALESCE(inserted.title, updated.title, new.title),
			COALESCE(inserted.blurb, updated.blurb, new.blurb),
			COALESCE(inserted.story, updated.story, new.story),
			COALESCE(inserted.dateStart, updated.dateStart),
			COALESCE(inserted.dateEnd, updated.dateEnd),
			COALESCE(inserted.published, updated.published, new.published)
		FROM new
		LEFT JOIN inserted
			ON inserted.title = new.title
			AND inserted.blurb = new.blurb
			AND inserted.story = new.story
		LEFT JOIN updated
			ON updated.id = new.id
	)

	SELECT * FROM results;
END;
$$
LANGUAGE plpgsql
COST 100;

GRANT SELECT ON story TO postgres;
GRANT SELECT ON photo TO postgres;
GRANT SELECT ON story_photo TO postgres;
GRANT SELECT ON site TO postgres;
GRANT SELECT ON story_site TO postgres;

GRANT SELECT ON hnm.favourites TO postgres;
GRANT INSERT ON hnm.favourites TO postgres;
GRANT SELECT ON favourites TO postgres;
GRANT INSERT ON favourites TO postgres;
GRANT USAGE ON favourites_id_seq TO postgres;

GRANT SELECT ON hnm.views TO postgres;
GRANT INSERT ON hnm.views TO postgres;
GRANT SELECT ON views TO postgres;
GRANT INSERT ON views TO postgres;
GRANT USAGE ON views_id_seq TO postgres;

GRANT ALL ON SCHEMA hnm TO postgres;
GRANT SELECT ON hnm.story_discover TO postgres;
GRANT SELECT ON hnm.story_details TO postgres;
GRANT SELECT ON hnm.view_stats TO postgres;
GRANT SELECT ON hnm.favourite_stats TO postgres;
GRANT SELECT ON hnm.stats TO postgres;

-- These permissions need to be given to a password protected role in the future
GRANT SELECT ON hnm.story TO postgres;
GRANT SELECT ON story TO postgres;
GRANT USAGE ON story_id_seq TO postgres;

GRANT SELECT ON hnm.story_site TO postgres;
GRANT SELECT ON story_site TO postgres;
GRANT USAGE ON story_site_id_seq TO postgres;

GRANT SELECT ON hnm.story_photo TO postgres;
GRANT SELECT ON story_photo TO postgres;
GRANT USAGE ON story_photo_id_seq TO postgres;
