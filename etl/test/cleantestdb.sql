-- clean test database (testdb)
DROP TABLE IF EXISTS favourites, links, photo, site, story, story_photo, story_site, views CASCADE;
DROP SCHEMA IF EXISTS hnm CASCADE;