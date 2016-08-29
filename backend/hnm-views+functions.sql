-- This file defines views and functions only; so it's safe to wipe all those
-- and recreate them every time. That allows us to update the API interface
-- easily without touching the tables that contain data.

SET client_min_messages TO WARNING; -- don't give notices from DROP SCHEMA ... CASCADE (we know it cascades)
DROP SCHEMA IF EXISTS hnm CASCADE;
SET client_min_messages TO NOTICE; -- notices OK after DROP SCHEMA

CREATE SCHEMA hnm

    -- produces the content we need for the map interface:
    --   sites with lat+Lng + photo,
    --   and each site with a list of associated stories (just id and title)
    CREATE VIEW all_site AS
        SELECT
            site.id,
            site.latitude,
            site.longitude,
            site.name,
            (SELECT COUNT(*) FROM story_site WHERE story_site.site_id = site.id) AS story_count,
            (SELECT photo FROM photo
                JOIN story_photo ON story_photo.photo_id = photo.id
                WHERE story_photo.story_id = story_site.story_id LIMIT 1) AS featured_photo,
            (SELECT json_agg(
                json_object(
                    '{id, title}',
                    ARRAY[
                        story.id::text,
                        story.title
                        ])::jsonb)
                FROM story
                WHERE story.id = story_site.story_id) AS stories
        FROM site
        LEFT JOIN story_site ON story_site.site_id = site.id


    -- view useful for testing photo URLs for each site
    CREATE VIEW site_photos AS
        SELECT site.id AS site_id, site.name AS site_name, photo.id AS photo_id, photo.photo
        FROM site
        JOIN story_site ON story_site.site_id = site.id
        JOIN story_photo ON story_photo.story_id = story_site.story_id
        JOIN photo ON photo.id = story_photo.photo_id


    CREATE VIEW story_featured_photos AS
        SELECT
            story_id,
            -- we assume that the lowest photo_id is the first added.
            -- content editors can put put their desired featured photo as the first
            -- in the list of pictures.
            -- see also: http://stackoverflow.com/questions/3800551/select-first-row-in-each-group-by-group
            min(photo_id) AS photo_id
        FROM story_photo
        GROUP BY story_id

    -- Get a "featured photo" (first photo from spreadsheet) for a story.
    CREATE VIEW story_featured_photo_urls AS
        SELECT
            story_featured_photos.story_id,
            photo.photo AS photo_url
        FROM story_featured_photos
        JOIN photo ON photo.id = story_featured_photos.photo_id


    CREATE VIEW story_discover AS
        SELECT DISTINCT ON (story.id) -- just picks one row https://www.postgresql.org/message-id/22uphu0hohpbnvg3a6d4qv21ofr4di7kda%404ax.com
            story.id, story.title, story.blurb, photo.photo,
            json_agg(DISTINCT json_object('{id, name, architectural_style, heritage_categories}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name, site.architectural_style, site.heritage_categories])::jsonb) AS sites
        FROM story
        LEFT JOIN story_photo ON story_photo.story_id = story.id
        LEFT JOIN photo       ON story_photo.photo_id = photo.id
        LEFT JOIN story_site  ON story_site.story_id  = story.id
        LEFT JOIN site        ON story_site.site_id   = site.id
        GROUP BY (story.id, site.id, photo.id)


    CREATE VIEW story_details AS
        SELECT
            story.id, story.title, story.blurb, story.story, story.quote,
            min(site.suburb) AS suburb,
            json_agg(DISTINCT photo.photo) AS photos,
            json_object('{start, end}', ARRAY[to_char(story.dateStart, 'YYYY-MM-DD'), to_char(story.dateEnd, 'YYYY-MM-DD')]) AS dates,
            json_agg(DISTINCT json_object('{id, name, architectural_style, heritage_categories}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name, site.architectural_style, site.heritage_categories])::jsonb) AS sites,
            json_agg(DISTINCT json_object('{lat, lng}', ARRAY[site.latitude, site.longitude])::jsonb) AS locations,
            json_agg(DISTINCT json_object('{url, title}', ARRAY[links.link_url, links.link_title])::jsonb) AS links
        FROM story
        LEFT JOIN story_photo ON story_photo.story_id = story.id
        LEFT JOIN photo       ON story_photo.photo_id = photo.id
        LEFT JOIN links       ON links.story_id       = story.id
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

CREATE OR REPLACE FUNCTION hnm.story_discover_by_location(lat TEXT, lng TEXT)
    RETURNS TABLE (
        id INTEGER,
        title TEXT,
        blurb TEXT,
        photo TEXT,
        distance FLOAT,
        sites JSONB
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
        )) AS distance,
        jsonb_agg(DISTINCT json_object('{id, name, architectural_style, heritage_categories}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name, site.architectural_style, site.heritage_categories])::jsonb) AS sites
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


-- Returns all sites (with optional row limit), including and sorted by distance from location passed in.
-- if count is passed in, the result will be limited to `count` rows (default: return all rows)
CREATE OR REPLACE FUNCTION hnm.sites_near_location(lat TEXT, lng TEXT, count INT DEFAULT null)
    RETURNS TABLE (
        -- all the fields from `site` table:
        site_id INTEGER,
        heritageItemId INT,
        name TEXT,
        suburb TEXT,
        address TEXT,
        latitude TEXT,
        longitude TEXT,
        architectural_style TEXT,
        heritage_categories TEXT,
        -- plus the following:
        distance FLOAT -- in meters, between this site and the location passed in
    ) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        site.*,
        ST_Distance_Sphere(
            ST_GeomFromText('POINT('||site.longitude||' '||site.latitude||')'),
            ST_GeomFromText('POINT('||$2||' '||$1||')')
        ) AS distance
    FROM site
    ORDER BY distance ASC
    LIMIT $3; -- by default, $3 = null and LIMIT null returns all rows
END;
$$
LANGUAGE plpgsql STABLE -- STABLE because we don't change the database and so long as the DB isn't changed, function results don't change.
COST 100;


--
-- For each story, return no more than one site (if there are multiple, the site closest the user's location is returned).
--
-- A story can exist in multiple sites; this gives just the closest site.
-- (For example, the hypothetical story "Invasion and Genocide" would apply in many places,
--  and if we don't want to see duplicate stories at multiple sites, we'd need the function below.)
-- To understand it, it might help to start by examining a simplifed stories_sites_distances
-- with an example location like ('-33.825','151.013'):
--    SELECT story_site.story_id, sd.site_id, sd.name, sd.suburb, sd.distance -- note: we're just taking some, not all columns
--    FROM hnm.sites_near_location('-33.825','151.013') sd JOIN story_site ON sd.site_id=story_site.site_id ;
--
--  story_id | site_id |                           name                           |     suburb     |   distance
-- ----------+---------+----------------------------------------------------------+----------------+---------------
--         1 |       1 | Old Government House                                     | Parramatta     | 1998.62502417
--         2 |       2 | Experiment House and Cottage                             | Harris Park    |  529.46202334
--         1 |       2 | Experiment House and Cottage                             | Harris Park    |  529.46202334
--         3 |       3 | Parramatta Sandbank                                      | Parramatta CBD |  881.05927817
--
-- Story 1 is associated with two locations (Old Gov house, and Experiment house).
-- When the user is looking for stories, we'll give them stories (1, 2, and 3) above, but because Experiment house is closer when they read story 1 they'll
-- see Experiment House listed as the closest location.
--
-- Sidenote: the example above is contrived, and stories existing in multiple locations is something Kenni and AG decided we should support.
--
-- Read http://postgresguide.com/tips/window.html to see how the PARTITION/rank() stuff works below.
--
CREATE OR REPLACE FUNCTION hnm.nearest_site_for_stories(lat TEXT, lng TEXT)
    RETURNS TABLE (
        story_id INT,
        site_id INT,
        heritageitemid INT,
        name TEXT,
        suburb TEXT,
        address TEXT,
        latitude TEXT,
        longitude TEXT,
        distance FLOAT -- in meters
        ) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        nearest_site_for_story.story_id,
        nearest_site_for_story.site_id,
        nearest_site_for_story.heritageitemid,
        nearest_site_for_story.name,
        nearest_site_for_story.suburb,
        nearest_site_for_story.address,
        nearest_site_for_story.latitude,
        nearest_site_for_story.longitude,
        nearest_site_for_story.distance
    FROM
        ( SELECT *, rank() OVER
            ( PARTITION BY stories_sites_distances.story_id ORDER BY stories_sites_distances.distance ASC) FROM
                ( SELECT story_site.story_id, sd.* from hnm.sites_near_location($1,$2) sd JOIN story_site ON sd.site_id=story_site.site_id ) stories_sites_distances
        ) nearest_site_for_story
    WHERE rank = 1; -- rank 1, when ordered by distances from smallest to largest, gives nearest sites
END;
$$
LANGUAGE plpgsql STABLE
COST 100;


-- TODO: make this actually use the view story_details (or a common view used by that as well, to reduce SQL code)
CREATE OR REPLACE FUNCTION hnm.story_details_by_location(lat TEXT, lng TEXT, story_of_interest INT) -- story: story ID
    RETURNS TABLE (
        id INTEGER,
        title TEXT,
        blurb TEXT,
        story TEXT,
        quote TEXT,
        suburb TEXT, -- suburb for the site associated with the story and closest to the provided location
        distance FLOAT, -- distance in meters to closest site for the story
        photos JSONB,
        dates JSONB,
        sites JSONB,
        locations JSONB,
        links JSONB
    ) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        story.id, story.title, story.blurb, story.story, story.quote,
        MIN(nearest_site.suburb) suburb, -- MIN() is no different than taking the first, since nearest_site.suburb is same for any given story
        MIN(nearest_site.distance) distance, -- MIN(d1,d1,d1) = d1. They're the same distance.
        jsonb_agg(DISTINCT photo.photo) AS photos,
        jsonb_object('{start, end}', ARRAY[to_char(story.dateStart, 'YYYY-MM-DD'), to_char(story.dateEnd, 'YYYY-MM-DD')]) AS dates,
        jsonb_agg(DISTINCT json_object('{id, name, architectural_style, heritage_categories}', ARRAY[to_char(site.heritageItemId, '9999999'), site.name, site.architectural_style, site.heritage_categories])::jsonb) AS sites,
        jsonb_agg(DISTINCT json_object('{lat, lng}', ARRAY[site.latitude, site.longitude])::jsonb) AS locations,
        jsonb_agg(DISTINCT json_object('{url, title}', ARRAY[links.link_url, links.link_title])::jsonb) AS links
    FROM story
    LEFT JOIN story_photo ON story_photo.story_id = story.id
    LEFT JOIN photo       ON story_photo.photo_id = photo.id
    LEFT JOIN links       ON links.story_id       = story.id
    LEFT JOIN story_site  ON story_site.story_id  = story.id
    LEFT JOIN site        ON story_site.site_id   = site.id
    LEFT JOIN hnm.nearest_site_for_stories($1, $2) nearest_site ON story.id = nearest_site.story_id
    WHERE story.id = $3
    GROUP BY story.id
    ORDER BY distance ASC;
END;
$$
LANGUAGE plpgsql STABLE -- STABLE because we don't change the database and so long as the DB isn't changed, function results don't change.
COST 100;


-- search for story title matches to query
CREATE OR REPLACE FUNCTION hnm.search_stories(query TEXT)
    RETURNS TABLE (
        id INTEGER,
        title TEXT,
        photo_url TEXT
    ) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        story.id,
        story.title,
        (SELECT hnm.story_featured_photo_urls.photo_url FROM hnm.story_featured_photo_urls WHERE story_id = story.id)
    FROM story
    WHERE story.title ~* $1; -- ~*: case insensitive regex match
END;
$$
LANGUAGE plpgsql STABLE -- STABLE because we don't change the database and so long as the DB isn't changed, function results don't change.
COST 100;

