CREATE TABLE IF NOT EXISTS story (
	id SERIAL PRIMARY KEY,
	title TEXT,
	blurb TEXT,
	story TEXT,
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
	latitude TEXT,
	longitude TEXT
);

CREATE TABLE IF NOT EXISTS story_site (
	id SERIAL PRIMARY KEY,
	story_id SERIAL REFERENCES story (id),
	site_id SERIAL REFERENCES site (id)
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

GRANT SELECT ON story TO postgres;
GRANT SELECT ON photo TO postgres;
GRANT SELECT ON story_photo TO postgres;
GRANT SELECT ON site TO postgres;
GRANT SELECT ON story_site TO postgres;
GRANT ALL ON SCHEMA hnm TO postgres;
GRANT ALL ON hnm.story_discover TO postgres;
GRANT ALL ON hnm.story_details TO postgres;
