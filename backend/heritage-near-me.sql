CREATE TABLE IF NOT EXISTS story (
	id SERIAL PRIMARY KEY,
	title TEXT,
	blurb TEXT,
	story TEXT,
	quote TEXT,
	dateStart DATE,
	dateEnd DATE
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
	address TEXT,
	latitude TEXT,
	longitude TEXT
);

CREATE TABLE IF NOT EXISTS story_site (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	site_id SERIAL REFERENCES site (id)
);

CREATE TABLE IF NOT EXISTS links (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	link_url TEXT,
	link_title TEXT
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

	CREATE VIEW story_details AS
		SELECT
			story.id, story.title, story.blurb, story.story,
			min(site.suburb) AS suburb,
			json_agg(photo.photo) AS photos,
			json_object('{start, end}', ARRAY[to_char(story.dateStart, 'YYYY-MM-DD'), to_char(story.dateEnd, 'YYYY-MM-DD')]) AS dates,
			json_agg(DISTINCT json_object('{id, name}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name])::jsonb) AS sites,
			json_agg(DISTINCT json_object('{lat, lng}', ARRAY[site.latitude, site.longitude])::jsonb) AS locations
		FROM story
		LEFT JOIN story_photo ON story_photo.story_id = story.id
		LEFT JOIN photo       ON story_photo.photo_id = photo.id
		LEFT JOIN story_site  ON story_site.story_id  = story.id
		LEFT JOIN site        ON story_site.site_id   = site.id
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
;

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
	GROUP BY story.id
	ORDER BY distance ASC;
END;
$$
LANGUAGE plpgsql VOLATILE
COST 100;

-- GRANT SELECT ON story TO postgres;
-- GRANT SELECT ON photo TO postgres;
-- GRANT SELECT ON story_photo TO postgres;
-- GRANT SELECT ON site TO postgres;
-- GRANT SELECT ON story_site TO postgres;

-- GRANT SELECT ON hnm.favourites TO postgres;
-- GRANT INSERT ON hnm.favourites TO postgres;
-- GRANT SELECT ON favourites TO postgres;
-- GRANT INSERT ON favourites TO postgres;
-- GRANT USAGE ON favourites_id_seq TO postgres;

-- GRANT SELECT ON hnm.views TO postgres;
-- GRANT INSERT ON hnm.views TO postgres;
-- GRANT SELECT ON views TO postgres;
-- GRANT INSERT ON views TO postgres;
-- GRANT USAGE ON views_id_seq TO postgres;

-- GRANT ALL ON SCHEMA hnm TO postgres;
-- GRANT SELECT ON hnm.story_discover TO postgres;
-- GRANT SELECT ON hnm.story_details TO postgres;
-- GRANT SELECT ON hnm.view_stats TO postgres;
-- GRANT SELECT ON hnm.favourite_stats TO postgres;
-- GRANT SELECT ON hnm.stats TO postgres;
