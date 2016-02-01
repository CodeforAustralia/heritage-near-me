CREATE TABLE IF NOT EXISTS story (
	id SERIAL PRIMARY KEY,
	title TEXT,
	story TEXT
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

CREATE SCHEMA hnm
	CREATE VIEW story_discover AS
		SELECT DISTINCT ON (story.id)
			story.id, story.title, photo.photo
		FROM story
		LEFT JOIN story_photo ON story_photo.story_id = story.id
		LEFT JOIN photo       ON story_photo.photo_id = photo.id

	CREATE VIEW story_details AS
		SELECT
			story.id, story.title, story.story, json_agg(photo.photo) as photos
		FROM story
		LEFT JOIN story_photo ON story_photo.story_id = story.id
		LEFT JOIN photo       ON story_photo.photo_id = photo.id
		GROUP BY story.id
