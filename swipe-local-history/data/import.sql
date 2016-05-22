BEGIN TRANSACTION;

-- Clear out previous data if it exists (for a fresh start)
-- DROP TABLE IF EXISTS site, story, story_site;

-- Create temporary data tables
CREATE TEMP TABLE temp_sites (
	heritageItemId SERIAL,
	name TEXT,
	suburb TEXT,
	latitude TEXT,
	longitude TEXT
);

CREATE TEMP TABLE temp_stories (
	id SERIAL PRIMARY KEY,
	title TEXT,
	story TEXT
);

-- Copy in the data
\COPY temp_sites FROM 'sites.csv' WITH CSV HEADER;
\COPY temp_stories FROM 'stories.csv' WITH CSV HEADER;

-- Remove poor data
DELETE FROM temp_sites
	WHERE
	(latitude = '' OR latitude IS NULL)
	OR 
	(longitude = '' OR longitude IS NULL)
;

DELETE FROM temp_stories
	WHERE
	(story = '' OR story IS NULL)
;

-- Reset SERIAL ids
-- SELECT setval(pg_get_serial_sequence('site', 'id'), coalesce(max(id),0) + 1, false) FROM temp_sites;
-- SELECT setval(pg_get_serial_sequence('story', 'id'), coalesce(max(id),0) + 1, false) FROM temp_stories;
-- SELECT setval(pg_get_serial_sequence('story_site', 'id'), coalesce(max(id),0) + 1, false) FROM story_site;

-- Insert the data
CREATE TABLE site (heritageItemId, name, suburb, latitude, longitude) AS (
	SELECT *
	FROM temp_sites
);

CREATE TABLE story (id, title, story) AS (
	SELECT *
	FROM temp_stories
);

-- Link the sites and stories
CREATE TABLE story_site (story_id, site_id) AS (
	SELECT story.id, site.heritageItemId
	FROM temp_stories AS story
	LEFT JOIN site
		ON site.heritageItemId = story.id
	WHERE story.id IS NOT NULL
	AND site.heritageItemId IS NOT NULL
);

COMMIT;
