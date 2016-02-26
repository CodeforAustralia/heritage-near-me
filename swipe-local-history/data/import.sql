BEGIN TRANSACTION;

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
SELECT setval(pg_get_serial_sequence('site', 'id'), coalesce(max(id),0) + 1, false) FROM site;
SELECT setval(pg_get_serial_sequence('story', 'id'), coalesce(max(id),0) + 1, false) FROM story;
SELECT setval(pg_get_serial_sequence('story_site', 'id'), coalesce(max(id),0) + 1, false) FROM story_site;

-- Insert the data
INSERT INTO site (heritageItemId, name, suburb, latitude, longitude) (
	SELECT *
	FROM temp_sites
);

INSERT INTO story (id, title, story) (
	SELECT *
	FROM temp_stories
);

-- Link the sites and stories
INSERT INTO story_site (story_id, site_id) (
	SELECT story.id, site.id
	FROM temp_stories AS story
	LEFT JOIN site
		ON site.heritageItemId = story.id
	WHERE story.id IS NOT NULL
	AND site.id IS NOT NULL
);

COMMIT;
