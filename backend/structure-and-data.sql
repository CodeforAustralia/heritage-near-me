--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

ALTER TABLE IF EXISTS ONLY public.views DROP CONSTRAINT IF EXISTS views_story_id_fkey;
ALTER TABLE IF EXISTS ONLY public.story_site DROP CONSTRAINT IF EXISTS story_site_story_id_fkey;
ALTER TABLE IF EXISTS ONLY public.story_site DROP CONSTRAINT IF EXISTS story_site_site_id_fkey;
ALTER TABLE IF EXISTS ONLY public.story_photo DROP CONSTRAINT IF EXISTS story_photo_story_id_fkey;
ALTER TABLE IF EXISTS ONLY public.story_photo DROP CONSTRAINT IF EXISTS story_photo_photo_id_fkey;
ALTER TABLE IF EXISTS ONLY public.links DROP CONSTRAINT IF EXISTS links_story_id_fkey;
ALTER TABLE IF EXISTS ONLY public.favourites DROP CONSTRAINT IF EXISTS favourites_story_id_fkey;
SET search_path = hnm, pg_catalog;

DROP RULE IF EXISTS "_RETURN" ON hnm.story_details;
DROP RULE IF EXISTS "_RETURN" ON hnm.story_discover;
SET search_path = public, pg_catalog;

ALTER TABLE IF EXISTS ONLY public.views DROP CONSTRAINT IF EXISTS views_pkey;
ALTER TABLE IF EXISTS ONLY public.story_site DROP CONSTRAINT IF EXISTS story_site_pkey;
ALTER TABLE IF EXISTS ONLY public.story DROP CONSTRAINT IF EXISTS story_pkey;
ALTER TABLE IF EXISTS ONLY public.story_photo DROP CONSTRAINT IF EXISTS story_photo_pkey;
ALTER TABLE IF EXISTS ONLY public.site DROP CONSTRAINT IF EXISTS site_pkey;
ALTER TABLE IF EXISTS ONLY public.photo DROP CONSTRAINT IF EXISTS photo_pkey;
ALTER TABLE IF EXISTS ONLY public.links DROP CONSTRAINT IF EXISTS links_pkey;
ALTER TABLE IF EXISTS ONLY public.favourites DROP CONSTRAINT IF EXISTS favourites_pkey;
ALTER TABLE IF EXISTS public.views ALTER COLUMN story_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.views ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_site ALTER COLUMN site_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_site ALTER COLUMN story_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_site ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_photo ALTER COLUMN photo_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_photo ALTER COLUMN story_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story_photo ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.story ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.site ALTER COLUMN heritageitemid DROP DEFAULT;
ALTER TABLE IF EXISTS public.site ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.photo ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.links ALTER COLUMN story_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.links ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.favourites ALTER COLUMN story_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.favourites ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.views_story_id_seq;
DROP SEQUENCE IF EXISTS public.views_id_seq;
DROP SEQUENCE IF EXISTS public.story_site_story_id_seq;
DROP SEQUENCE IF EXISTS public.story_site_site_id_seq;
DROP SEQUENCE IF EXISTS public.story_site_id_seq;
DROP TABLE IF EXISTS public.story_site;
DROP SEQUENCE IF EXISTS public.story_photo_story_id_seq;
DROP SEQUENCE IF EXISTS public.story_photo_photo_id_seq;
DROP SEQUENCE IF EXISTS public.story_photo_id_seq;
DROP TABLE IF EXISTS public.story_photo;
DROP SEQUENCE IF EXISTS public.story_id_seq;
DROP SEQUENCE IF EXISTS public.site_id_seq;
DROP SEQUENCE IF EXISTS public.site_heritageitemid_seq;
DROP TABLE IF EXISTS public.site;
DROP SEQUENCE IF EXISTS public.photo_id_seq;
DROP TABLE IF EXISTS public.photo;
DROP SEQUENCE IF EXISTS public.links_story_id_seq;
DROP SEQUENCE IF EXISTS public.links_id_seq;
DROP TABLE IF EXISTS public.links;
DROP SEQUENCE IF EXISTS public.favourites_story_id_seq;
DROP SEQUENCE IF EXISTS public.favourites_id_seq;
SET search_path = hnm, pg_catalog;

DROP VIEW IF EXISTS hnm.views;
DROP TABLE IF EXISTS hnm.story_discover;
DROP TABLE IF EXISTS hnm.story_details;
DROP VIEW IF EXISTS hnm.stats;
SET search_path = public, pg_catalog;

DROP TABLE IF EXISTS public.story;
SET search_path = hnm, pg_catalog;

DROP VIEW IF EXISTS hnm.view_stats;
SET search_path = public, pg_catalog;

DROP TABLE IF EXISTS public.views;
SET search_path = hnm, pg_catalog;

DROP VIEW IF EXISTS hnm.favourites;
DROP VIEW IF EXISTS hnm.favourite_stats;
SET search_path = public, pg_catalog;

DROP TABLE IF EXISTS public.favourites;
SET search_path = hnm, pg_catalog;

DROP FUNCTION IF EXISTS hnm.story_discover_by_location(lat text, lng text);
DROP FUNCTION IF EXISTS hnm.story_details_by_location(lat text, lng text, story_of_interest integer);
DROP FUNCTION IF EXISTS hnm.sites_near_location(lat text, lng text, count integer);
DROP FUNCTION IF EXISTS hnm.nearest_site_for_stories(lat text, lng text);
DROP EXTENSION IF EXISTS postgis;
DROP EXTENSION IF EXISTS plpgsql;
DROP SCHEMA IF EXISTS public;
DROP SCHEMA IF EXISTS hnm;
--
-- Name: hnm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA hnm;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = hnm, pg_catalog;

--
-- Name: nearest_site_for_stories(text, text); Type: FUNCTION; Schema: hnm; Owner: -
--

CREATE FUNCTION nearest_site_for_stories(lat text, lng text) RETURNS TABLE(story_id integer, site_id integer, heritageitemid integer, name text, suburb text, address text, latitude text, longitude text, distance double precision)
    LANGUAGE plpgsql STABLE
    AS $_$
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
$_$;


--
-- Name: sites_near_location(text, text, integer); Type: FUNCTION; Schema: hnm; Owner: -
--

CREATE FUNCTION sites_near_location(lat text, lng text, count integer DEFAULT NULL::integer) RETURNS TABLE(site_id integer, heritageitemid integer, name text, suburb text, address text, latitude text, longitude text, architectural_style text, heritage_categories text, distance double precision)
    LANGUAGE plpgsql STABLE
    AS $_$
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
$_$;


--
-- Name: story_details_by_location(text, text, integer); Type: FUNCTION; Schema: hnm; Owner: -
--

CREATE FUNCTION story_details_by_location(lat text, lng text, story_of_interest integer) RETURNS TABLE(id integer, title text, blurb text, story text, quote text, suburb text, distance double precision, photos jsonb, dates jsonb, sites jsonb, locations jsonb, links jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
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
$_$;


--
-- Name: story_discover_by_location(text, text); Type: FUNCTION; Schema: hnm; Owner: -
--

CREATE FUNCTION story_discover_by_location(lat text, lng text) RETURNS TABLE(id integer, title text, blurb text, photo text, distance double precision, sites jsonb)
    LANGUAGE plpgsql
    AS $_$
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
$_$;


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: favourites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE favourites (
    id integer NOT NULL,
    datetime timestamp without time zone,
    story_id integer NOT NULL,
    favourited boolean
);


SET search_path = hnm, pg_catalog;

--
-- Name: favourite_stats; Type: VIEW; Schema: hnm; Owner: -
--

CREATE VIEW favourite_stats AS
 SELECT favourites.story_id,
    sum(
        CASE
            WHEN (favourites.favourited IS NOT NULL) THEN 1
            ELSE 0
        END) AS total_choices,
    sum(
        CASE
            WHEN (favourites.favourited = true) THEN 1
            ELSE 0
        END) AS favourites,
    sum(
        CASE
            WHEN (favourites.favourited = false) THEN 1
            ELSE 0
        END) AS passes
   FROM public.favourites
  GROUP BY favourites.story_id;


--
-- Name: favourites; Type: VIEW; Schema: hnm; Owner: -
--

CREATE VIEW favourites AS
 SELECT favourites.id,
    favourites.datetime,
    favourites.story_id,
    favourites.favourited
   FROM public.favourites;


SET search_path = public, pg_catalog;

--
-- Name: views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE views (
    id integer NOT NULL,
    datetime timestamp without time zone,
    story_id integer NOT NULL
);


SET search_path = hnm, pg_catalog;

--
-- Name: view_stats; Type: VIEW; Schema: hnm; Owner: -
--

CREATE VIEW view_stats AS
 SELECT views.story_id,
    sum(
        CASE
            WHEN (views.id IS NOT NULL) THEN 1
            ELSE 0
        END) AS views
   FROM public.views
  GROUP BY views.story_id;


SET search_path = public, pg_catalog;

--
-- Name: story; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE story (
    id integer NOT NULL,
    title text,
    blurb text,
    story text,
    quote text,
    datestart date,
    dateend date
);


SET search_path = hnm, pg_catalog;

--
-- Name: stats; Type: VIEW; Schema: hnm; Owner: -
--

CREATE VIEW stats AS
 SELECT story.id,
    story.title,
    favourite_stats.total_choices,
    favourite_stats.favourites,
    favourite_stats.passes,
    view_stats.views
   FROM ((public.story
     LEFT JOIN favourite_stats ON ((favourite_stats.story_id = story.id)))
     LEFT JOIN view_stats ON ((view_stats.story_id = story.id)));


--
-- Name: story_details; Type: TABLE; Schema: hnm; Owner: -
--

CREATE TABLE story_details (
    id integer,
    title text,
    blurb text,
    story text,
    quote text,
    suburb text,
    photos json,
    dates json,
    sites json,
    locations json,
    links json
);

ALTER TABLE ONLY story_details REPLICA IDENTITY NOTHING;


--
-- Name: story_discover; Type: TABLE; Schema: hnm; Owner: -
--

CREATE TABLE story_discover (
    id integer,
    title text,
    blurb text,
    photo text,
    sites json
);

ALTER TABLE ONLY story_discover REPLICA IDENTITY NOTHING;


--
-- Name: views; Type: VIEW; Schema: hnm; Owner: -
--

CREATE VIEW views AS
 SELECT views.id,
    views.datetime,
    views.story_id
   FROM public.views;


SET search_path = public, pg_catalog;

--
-- Name: favourites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE favourites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favourites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE favourites_id_seq OWNED BY favourites.id;


--
-- Name: favourites_story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE favourites_story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favourites_story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE favourites_story_id_seq OWNED BY favourites.story_id;


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE links (
    id integer NOT NULL,
    story_id integer NOT NULL,
    link_url text,
    link_title text
);


--
-- Name: links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE links_id_seq OWNED BY links.id;


--
-- Name: links_story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE links_story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: links_story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE links_story_id_seq OWNED BY links.story_id;


--
-- Name: photo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE photo (
    id integer NOT NULL,
    photo text
);


--
-- Name: photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE photo_id_seq OWNED BY photo.id;


--
-- Name: site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE site (
    id integer NOT NULL,
    heritageitemid integer NOT NULL,
    name text,
    suburb text,
    address text,
    latitude text,
    longitude text,
    architectural_style text,
    heritage_categories text
);


--
-- Name: site_heritageitemid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE site_heritageitemid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_heritageitemid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE site_heritageitemid_seq OWNED BY site.heritageitemid;


--
-- Name: site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE site_id_seq OWNED BY site.id;


--
-- Name: story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_id_seq OWNED BY story.id;


--
-- Name: story_photo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE story_photo (
    id integer NOT NULL,
    story_id integer NOT NULL,
    photo_id integer NOT NULL
);


--
-- Name: story_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_photo_id_seq OWNED BY story_photo.id;


--
-- Name: story_photo_photo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_photo_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_photo_photo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_photo_photo_id_seq OWNED BY story_photo.photo_id;


--
-- Name: story_photo_story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_photo_story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_photo_story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_photo_story_id_seq OWNED BY story_photo.story_id;


--
-- Name: story_site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE story_site (
    id integer NOT NULL,
    story_id integer NOT NULL,
    site_id integer NOT NULL
);


--
-- Name: story_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_site_id_seq OWNED BY story_site.id;


--
-- Name: story_site_site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_site_site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_site_site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_site_site_id_seq OWNED BY story_site.site_id;


--
-- Name: story_site_story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE story_site_story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: story_site_story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE story_site_story_id_seq OWNED BY story_site.story_id;


--
-- Name: views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE views_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE views_id_seq OWNED BY views.id;


--
-- Name: views_story_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE views_story_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: views_story_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE views_story_id_seq OWNED BY views.story_id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY favourites ALTER COLUMN id SET DEFAULT nextval('favourites_id_seq'::regclass);


--
-- Name: story_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY favourites ALTER COLUMN story_id SET DEFAULT nextval('favourites_story_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY links ALTER COLUMN id SET DEFAULT nextval('links_id_seq'::regclass);


--
-- Name: story_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY links ALTER COLUMN story_id SET DEFAULT nextval('links_story_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY photo ALTER COLUMN id SET DEFAULT nextval('photo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY site ALTER COLUMN id SET DEFAULT nextval('site_id_seq'::regclass);


--
-- Name: heritageitemid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY site ALTER COLUMN heritageitemid SET DEFAULT nextval('site_heritageitemid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story ALTER COLUMN id SET DEFAULT nextval('story_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo ALTER COLUMN id SET DEFAULT nextval('story_photo_id_seq'::regclass);


--
-- Name: story_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo ALTER COLUMN story_id SET DEFAULT nextval('story_photo_story_id_seq'::regclass);


--
-- Name: photo_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo ALTER COLUMN photo_id SET DEFAULT nextval('story_photo_photo_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site ALTER COLUMN id SET DEFAULT nextval('story_site_id_seq'::regclass);


--
-- Name: story_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site ALTER COLUMN story_id SET DEFAULT nextval('story_site_story_id_seq'::regclass);


--
-- Name: site_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site ALTER COLUMN site_id SET DEFAULT nextval('story_site_site_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY views ALTER COLUMN id SET DEFAULT nextval('views_id_seq'::regclass);


--
-- Name: story_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY views ALTER COLUMN story_id SET DEFAULT nextval('views_story_id_seq'::regclass);


--
-- Data for Name: favourites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY favourites (id, datetime, story_id, favourited) FROM stdin;
\.


--
-- Name: favourites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('favourites_id_seq', 1, false);


--
-- Name: favourites_story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('favourites_story_id_seq', 1, false);


--
-- Data for Name: links; Type: TABLE DATA; Schema: public; Owner: -
--

COPY links (id, story_id, link_url, link_title) FROM stdin;
1	5	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
2	5	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
3	3	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5061073	OEH
4	5	http://parrapark.com.au/assets/Uploads/Resources/diy-walking-tours/Parramatta-Park-Monuments-and-Sites-Self-Guided-Walking-Tour	Parramatta Park Monuments and Sites - A self-guided walking tour
5	3	http://www.environment.nsw.gov.au/resources/heritagebranch/heritage/ParramattaArchaeologyTour.pdf	Parramatta archaeological sites walking tour
6	5	http://www.visitsydneyaustralia.com.au/aerial-adventures.html	Australia for Everyone Sydney
7	5	http://www.granvillehistorical.org.au/resources/Granville%20Guardian%202011%20November%20Final%20(2).pdf	Granville Historical Society
8	4	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051406	OEH
9	8	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
10	2	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5045475	OEH
11	4	http://trove.nla.gov.au/newspaper/article/85883220?searchTerm=Roxy%20theatre,%20Parramatta&searchLimits	Newspaper report of Gala Opening of Roxy Theatre
12	5	http://arc.parracity.nsw.gov.au/blog/2014/07/09/australias-first-aviator-billy-hart-parramatta-stories/	Parramatta Heritage Centre
13	8	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
14	6	http://sydneylivingmuseums.com.au/elizabeth-farm/visit	Visit Elizabeth Farm
15	7	http://www.discoverparramatta.com/places/heritage_and_historic_sites/brislington_medical_and_nursing_museum	Brislington
16	2	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
17	4	http://www.news.com.au/national/real-life-ghostbusters-check-out-the-roxy-theatre-in-sydney/story-fncynjr2-1226630734278	Ghost Stories
18	5	http://tlf.dlr.det.nsw.edu.au/learningobjects/Content/R11336/object/r3351.html	Flying in Australia
19	9	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
20	8	http://arc.parracity.nsw.gov.au/blog/2014/03/20/boer-war-memorial-parramatta-park-1904-by-w-hanson/	Parramatta Heritage Centre
21	6	http://blogs.hht.net.au/cook/the-vine-and-the-olive/	The Cook and the Curator blog: The Vine and the Olive
22	2	http://adb.anu.edu.au/biography/fitzroy-sir-charles-augustus-2049	Australian Dictionary of Biography
23	7	http://www.brislington.net/Brislington_Medical_%26_Nursing_Museum/History.html	Brislington
24	9	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
25	8	http://alh-research.tripod.com/Light_Horse/index.blog?start=1100440859	Australian Military History of the Early 20th Century
26	2	http://www.visitsydneyaustralia.com.au/insiders-memorials-sub.html	Visit Sydney
27	7	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051397	OEH
28	6	http://blogs.hht.net.au/cook/then-and-now-the-dining-room-at-elizabeth-farm/	The Macarthurs’ Dining Room
29	9	http://www.parramattasun.com.au/story/3079074/gallery-dairy-cottage-a-rare-insight-into-the-past/	Parramatta Sun
30	7	http://arc.parracity.nsw.gov.au/blog/2015/05/13/dr-walter-brown-of-brislington-house-parramatta/#more-3735	Dr Walter Brown
31	8	http://www.militaryhistorytours.com.au/	Military History Tours
32	2	http://www.castleofspirits.com/govhouse.html	Castle of Spirits
33	6	http://blogs.hht.net.au/cook/setting-the-macarthurs-table-at-the-spring-harvest-festival/	Setting the Macarthurs' Table
34	9	http://www.phansw.org.au/wp-content/uploads/2012/04/PhanfareNovDec2006.pdf	Professional Historians Association
35	10	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=4301684	OEH
36	11	http://www.environment.gov.au/heritage/places/national/old-government-house	OEH
37	12	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
38	1	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051403	OEH
39	6	http://blogs.hht.net.au/cook/ye-scurvy-dogs-it-be-talk-like-a-pirate-day/	More About Pirates
40	10	https://www.engineersaustralia.org.au/sites/default/files/shado/Learned%20Groups/Interest%20Groups/Engineering%20Heritage/EHA%20No_14%20Jun03.pdf	Engineers Australia
41	11	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
42	12	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
43	1	https://www.nationaltrust.org.au/places/experiment-farm-cottage/	National Trust
44	10	http://www.powerhousemuseum.com/mob/collection/database/?irn=416165&search=15&images=&wloc=&c=1&s=0	Powerhouse Museum
45	11	http://dictionaryofsydney.org/entry/parramatta_park	Dictionary of Sydney
46	12	http://acms.sl.nsw.gov.au/item/itemDetailPaged.aspx?itemID=944035	State Library of NSW
47	10	http://arc.parracity.nsw.gov.au/blog/2014/03/31/parramatta-gasworks-and-the-australian-gas-light-company/	Parramatta City
48	11	http://www.visitsydneyaustralia.com.au/parramatta.html	Visit Sydney Australia
49	12	http://researchonline.jcu.edu.au/24051/2/02part1-of-3.pdf	Analysis of Southern Star Clusters
50	11	http://parrapark.com.au/assets/Uploads/Resources/diy-walking-tours/Parramatta-Park-Monuments-and-Sites-Self-Guided-Walking-Tour	Parramatta Park Monuments and Sites - A self-guided walking tour
51	12	http://cycletraveller.com.au/australia/bike-routes/parramatta-historical-bike-tour	Cycle Traveller
52	15	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
53	12	http://www.southastrodel.com/Page032.htm	Southern Astronomers
54	15	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
55	13	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=2240368	OEH
56	15	http://parrapark.com.au/assets/Uploads/Resources/diy-walking-tours/Parramatta-Park-Monuments-and-Sites-Self-Guided-Walking-Tour	
57	16	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5000658	OEH
58	19	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5051462	OEH
63	19	https://www.nationaltrust.org.au/places/old-government-house/	National Trust
69	19	http://parrapark.com.au/assets/Uploads/Resources/diy-walking-tours/Parramatta-Park-Monuments-and-Sites-Self-Guided-Walking-Tour	Parramatta Park
75	19	http://www.theaustralian.com.au/news/home-grown/story-e6frg6n6-1111117688010	The Australian
59	14	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5000	OEH
64	14	http://trove.nla.gov.au/newspaper/article/75782597?searchTerm=Grafton%20Gaol%20escape&searchLimits=	Trove
70	14	http://www.dictionaryofsydney.org/entry/parramatta_gaol	Dictionary of Sydney
78	14	http://arc.parracity.nsw.gov.au/blog/2014/06/04/parramatta-gaol-2/	Parramatta Heritage Centre
82	14	http://www.dailymail.co.uk/news/article-2757466/Dark-deserted-creepy-reminders-inside-centuries-old-Parramatta-jail-rat-infested-den-iniquity-men-received-cruel-punishment-crazed-killer-ruined-young-girl-s-life.html	Daily Mail
60	13	http://www.abc.net.au/radionational/programs/religionreport/a-new-cathedral-for-parramatta/3532662#transcript	ABC Radio
71	13	http://www.stpatscathedral.com.au/index.php/history	St Patricks Cathedral
61	15	Parramatta	Park Monuments and Sites - A self-guided walking tour
65	15	http://www.dailytelegraph.com.au/newslocal/parramatta/parramatta-beach-not-so-farfetched-to-those-who-recall-days-of-diving-in-at-little-coogee/news-story/5c5f186f742311bf84acd0e240f72ada	Daily Telegraph
91	23	http://www.discoverparramatta.com/places/heritage_and_historic_sites/hambledon_cottage	Visit Hambledon Cottage
92	23	http://sydneylivingmuseums.com.au/elizabeth-farm	Visit Elizabeth Farm
93	23	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5052762	OEH
94	23	http://www.australia.gov.au/about-australia/australian-story/macarthurs-and-the-merino-sheep	John Macarthur and the Merino Sheep
62	16	http://dictionaryofsydney.org/entry/childrens_institutions_in_nineteenth-century_sydney	Dictionary of Sydney
67	16	http://www.uws.edu.au/femaleorphanschool/home/parramatta_campus_heritage_walk	 UWS Heritage Walk
74	16	http://www.dailytelegraph.com.au/newslocal/parramatta/restored-female-orphan-school-at-rydalmere-officially-opened-to-public/story-fngr8huy-1226727384947	Daily Telegraph
66	21	http://www.environment.gov.au/heritage/places/national/richmond	OEH
73	21	http://www.visitnsw.com/destinations/blue-mountains/katoomba-area/attractions/lennox-bridge-in-the-blue-mountains	Visit NSW
77	21	https://youtu.be/ffU1CAae8pA	Heritage Footage
68	17	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=2240207	OEH
79	17	http://trove.nla.gov.au/newspaper/article/17188946?searchTerm=woolpack%20inn,%20parramatta&searchLimits=l-availability=y|||l-australian=y	Trove
83	17	http://woolpackhotel.com.au/parramattahistory.htm	Woolpack Hotel
72	20	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=3540613	OEH
76	20	http://arc.parracity.nsw.gov.au/blog/2015/08/12/cumberland-hospital-forgotten-garden-precinct/	Parramatta City
80	20	http://arc.parracity.nsw.gov.au/blog/2015/08/07/parramatta-hospital-for-the-insane-destruction-of-female-factory-buildings-cumberland-hospital-1878-1983/	Parramatta Heritage Centre
81	22	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=5060990	OEH
84	22	http://sydneylivingmuseums.com.au/stories/hyde-park-barracks-clock	Sydney Living Museum
86	22	http://www.bniproject.com/history/	The Blacktown Native Institution Project
88	22	http://www.abc.net.au/radionational/programs/lifematters/the-native-institute/5089836	ABC Radio - The Native Institute
85	18	http://www.environment.nsw.gov.au/heritageapp/ViewHeritageItemDetails.aspx?ID=2242863	OEH
87	18	http://mgnsw.org.au/organisations/nsw-lancers-memorial-museum/	Lancers Memorial Museum
89	18	http://www.westlinkm7.com.au/about.php?Light-Horse-Sculpture-Parade-4	the M4 Freeway Light Horse Installation
90	18	http://www.lancers.org.au/	Royal NSW Lancers
\.


--
-- Name: links_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('links_id_seq', 94, true);


--
-- Name: links_story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('links_story_id_seq', 1, false);


--
-- Data for Name: photo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY photo (id, photo) FROM stdin;
1	https://lh3.googleusercontent.com/1C3_ucs9mXTyFgdEcUYkqjovWYQ-WGw4Q06Cc6tH7DqR4NjcZSgWRan9Eox0VrvcGkcdgx7bfOx8URhZ_fx6Z4oYQNRqTT2K2dcUKCI55L4C5aOPFSp5KdOcv8gf6CgcJRHCVYoWlLFkl63Nc-2ap3hwU4zbhXAv-85kh6SbcLCSpPV9dDTtwk0-j2lSX9hwnCE1Uk-pls0vo79HjtWwchz6mDadGoF_QqJPxI0xUW_5G1sZq8dJyguVfeUMWZe_u1s9mX5B7ycr7Q32RU5MYAK83Y8hPAE99BFn4-6XT37B9EZrZJkMchmx2pZEMIM8ZkwV4B0lS1E8I3rjGghWPT-oIYwXR75tRWPuFzUzLMGlJ3r7ltuoCZ8kvxNpoQJxUwid18zJGKyhrmtk-s_hfYa06oAtIE-K7O88jT-jw8I5yb5_SMyVlEmT2HJZBAqh-2UZhFtg4Nq91n3V5Y3lMZm_uqqk1tGMQoAa6Tq7L0yZfRSEZ4Qj5rnhZlIiWHjgEDwDevCtQXGT5pGSubL26gigvAIcJm3Q_qwvaAY1EGpRo64rJLYACOBEl9G-lPd9NuFFz2lNwPkby9aIgfPYE3lNQgnRB1g=w1200-h801-no
2	https://lh3.googleusercontent.com/qwi0giI5zv98LW2tU4xnO3unE7jUNlk1XfHZRu0M-BlKdD5tTgUixiO5eP0KWBOFhCkJYqID_yBwTPJjiutaHZgsvzdkNFSsAXXq7k5GRxCdcVZQMM2gulMEokii2EH-E4NeXx8st6fEXZrna19ACzsBl2OuAp2Jer-X5l9I5Wijjm6JwhgltMg00PBQJeFR6Xt8twnbn83FdfgTg6inv3dqZsiHsb-GUWmv5wlkW08UVYNM-zkTChnZsC2R3GeUufXpex7rgo6MEkIRbDd7EHYtryzSuinCMT0omeTNBisEIKkhm6h9Xow4pTm-Eqt_hjrHDP6UpwgFFNUNfWdQ69eTN2_Actl3U_LZePIrsEm9iWKbQnqBOWzBkrQCXOAE-nAAGHeqDbw-dtn663wXl4FjIY4ffXUcYXH84_8H5CZp3UW-JQ5Ze9KCGOxsunx6gW_dyVMXPGoOe9WxMsRT6Pj4sy2nC2jU8oMF0b85m_xSOlbKlj6KnDfQjU0EcXDZAaWT2zGoa8ztLhrTjcE7uo1FDIwWcE-qOPNuicI_4IsRYjU_thltZ0gBwjqULYWMXFw4ZJy9WYRmdroDSROkPx55nic7du8=w1988-h1326-no
3	https://lh3.googleusercontent.com/TFiDDpxk4JyBh_4f-0hta4R5-KITLJNA2RIf2tr0PKY7UjIvp4skvONMx4LnJkTsDPMir1YtVu3ig_E7T1u2OonpiiYGZF_bon1qTNeoeHzn2ySyyikPbVIhU_3J-N0_fMeE63b8SrblQpOwy3igs0ujFcuNjO186jBlevFgZ8E9kUdTpbbQGOsF0iBllC2Ce0Kp0_8IFCmbKs8cl6VdEXYtVCEVBYqLHMHyxPhWj7fBXBNNsMysb3lUd5b9O2D8_PVQ2wAb4w1dJuiWtNzZF5y6kQZ_jF-sqrlImZ70gfmle83lWKxPGZ2ykoRJfTrlSasDcSNcDqI6I3yWDZu4Jii0aYvfJV6H_DZlFtCFxSgY1g9sMeLxowkUyemh6RyMRW13SBSN_b-w7UmMjr3VmPscoctFtWXoKT7spjUCRl1vGwbBmmXXoBoNxq3WnaLmhPueYLKSR1Kk93UE3pF_stCNZSotCD_6tB4XEawEFW_S3dxpDDfulys9wu_siyI9CsoB1XoKZOHc6U9B07iFriv-9b96t6I28KHwfQWiYYqp0sjqdIB7LfPItyec2LvUn1kdRj8usffk8JrKKXFCGN3uwLFuAqs=w1988-h1326-no
4	https://lh3.googleusercontent.com/xLqYUvuLqfq-7eWM83pwsj9Fy-dKUDngXNqOx4ZbSD33euJCe76EdUuWhHKWR8nYUNJYn1KT8oThKfIAvmzBnw87QY5iq1E9FkgUo7GdVojuy9n59NafJoJ4id4DpyahlAvLDM6of8-Ug34T7ePBLVI5lcQ-Otx66We7ZwRPlmymoMPMBTQRbOq2hA6Ah0Iy326gf2p5k9HgwgiBhkRaDgEjVn2NVifAchdQBXxJXl7IujTgo6rLdV9ygbtHmUZWNizGsl98xOhdR46gsE5DK60RqkWDobNVpEz25EUy-4lgfxvVFiJk4M2vdjQHviT9X3--aQ_irgQvPFbIAU8U9ehAXi7EzdAz7lV7XrKPfzYB-_izLDhoq6jTzMjT0zmOkfZ-tbtgileju1uC1569GRlhkFN3BDSPqUCLS7at1nCsTAMq9BtSLwvGRvobR1_7me_c9yVOJVQCLXIMO2MPKfg-WR0FQk2NUQq75N5-ndCgnm8zicf-EJvbW8xZSzimIoXFX3YLwPRg5hDYQjxUrJu5PaaWrnGsP7sGBerXzmtAE-75hVdXdUELpNtTZrkhxJYSpYrMuB1s3hQfg6vHV7_lRZdTEFs=w1988-h1326-no
5	https://lh3.googleusercontent.com/zEWcGNsJ3wF3gVwHt04JTmUyv1P1mu_S9f6-jroD2VkzNyh8RGwNt1earP8iYR2yA2BbipAeOerMfNuS-k0YEKPCtviLwsaf2C2n_soRwnMDlF1x9-Gx6ZNNYSjjFjU7KWcmbtXSLDGmm0q2MquE8dLG9MCEPpbWeJyMQ5klzXNMma_N9ubOlm131czeJ2farK1pK7mc_gJhTgnO59PGkS1WVwVDOjrRqofZ1zqWCvOLo1iVulJfshi-SCudT-YGG2vslDXFuDgf1utPugECWGmA4PlPAx8yYDQc5WASe9gdJ4tSupEPEPE8EYMrHp7gACioRTzFkryHK_xwwxaUz7LmdKPnHA3Iti1xE2gu2pnTfeIYzyTMwou9YvPNXzJQZtNePyImEMNvSyXZjMHMYHs80F_RrAY2l4hhL7ms839ivx6Uvfi7h61ZpQ-He35r7oC5qhtMxGSBCzz75kF80Yxmh8iiAwbncossuPxgK2IspkYfgQUiYcaFSVtX16ODrUmfoSpeiLWq-VOzmqtWY0p6_Yupim-BYTA1SWBOWXV59Y6B-l0WVcAQNtaSsb17eq19l6WMtt5WKplSJvGu0_RB3klBBK8=w663-h442-no
6	https://lh3.googleusercontent.com/XqQ8msY3bapurNC5ecaoIMoOXakhCoJmDdIJ67Ghak0m9AM3igOamNd-nNejKaQZvWhtINyBbMzA8Le-DLaTQByo1Xl3dDWlyYvVaZ0e5ah0mngY8UTS-To-sD5seasY-4kv6F8f8-xhg2PyeZ6sU60Nbr9-EDQMi0h1quL4tEmx3TIpzo8RDhTKOFudFL1rIBD0SBkK2qYCTkTXMCb8a1u6eFB9J1tvsBdHAXuZy-2konqJUAWuE4PT2KhZnU810QPC6V0L_sAV69PdUelTRpwPGADvdIi3YB6RVkVxXxmp7zAWhUrHtuxzA3JmbQdYvzasJUoXX5cn99YcfmeEsn6-EvbUd23tObh4DaXEuRYbExUjtT5DgXzJ77Kb5G-s548h5ogC-RRem5ccMRoO7XHbqMUzSX-dk0NNvgGzcq-M5gFianYiyUrhUZ2_DCYlcRy_h_jF_6wSGXu_4Z5rhrbQMxMveocx_9oRcGlt62O_Wx1HWokfqWg1sD9j4tFgnA7tdD_80cLh0XpCRsJY7W7j5Xgmedb-dVGHExUJXbS5F5wIua6OPFbvTLjD3REq4Qa7dxx3FKYQaGC9dFYRaN1gnoBur00=w1168-h779-no
7	https://lh3.googleusercontent.com/eLJniHePF1lquDfBDG_RuoFEttIURX1zPhVl2DT82TZhvPp0a1vh1kYbh4VdOYkAtDZ6M5JdQyFio3faJ04ThJY9v_P9GA5AFmGxP-QHRdjImWKG5T5Dr7atiu47oiEZ0EBJ8mDbluemDoc6CbWMIHvAArksEipSESsGp9O4w4Kq5K1v7MnD57f_yiSvKihZ1jUFww9DOxsJYJE-CU8GAyFVl0K3iYo7lm7bXZ8r3NbmFE6nECygxgW7iopDq5VY-oJHELUJbgeLEQ8C6z_iUmPyulSblz8Vz7vhkrZGGjjp3rRAVv1WoBd63VIKvVHs60JlFKHvddNtwkcz26VoWIaQpKKMkLEN0T-9hpOkZQ0cTYyVhPWrI4hOXu0TLQG-eGWf7fM1bm38rOaBa4-F473C9oZhCmO5CqxPRDLoe3wZ3vCohkQ0ywKTODfNo4454JomPZeyk783SPCSN4S-ixupWNtHgrl2rFxHKwG6F60e0LH6xKOeBH83eP_pLrfUgiq3W8-U1R6PP1FhOLMpF0ExouRl_tkXBUFVREk9oYRfytHBGf8kLQkvCTjPpG8Tkm1H3bWmeO5my3Evn86qh-Ur3Ybz8yU=w1988-h1326-no
8	https://lh3.googleusercontent.com/VnvcydgYquhfSmbUxEStK3ZbuwFvt5XITeq3-KcxVrSxebUEzcbGNXyXm_LLRYZYocIxbAd-PXXjVN5-Wwuu1MaegIisqXd6XaoudH3auwgRJADpig6HOg-G6ZkUz2j2noYwLQmKNFqTMIS3b3QksZXHE7PINgXnW9l6jeN3YZQCRWXFUqG2YyDOxceNtAB4YKYt0bRQzh7WhJ9EoCatKJlFrFkNo-vl1v5smvsh4UXrwV312OD9Sk-INMW_HIMVgaEQBx_Y1gkcbxhXd8vGHglWsl9EWADYs71jiGYc91r81Db8LZZokEpK7sQUJpW4o9quMJKJ4bLrtRqBnoIEWKaXrp2cmty8RwcUjiiKZD2-auPF0myC_ZrWnxVysppoQo1lvnnGbbQQUvzNxw7ptP16qfa_AMygbYKHus1XVQSplOIpPK5srXwy-6IZKkzfsX6sZfAUbCYeZLslJXMUNxo6XJ7EP_1OAISe5y7_VIaNAuwUwbb80ekjmK-mH_kTgWUexgJYYGyWLuLOiIprbfuAhbx78tSgYkf7FJVOnQRqTTRKxkcQKNblfB3fmN206ac4lpIf6_rT5N1mIRtEhwOtSudNh-4=w1200-h801-no
9	https://lh3.googleusercontent.com/nTV2Fs-kut4LmNxcy6cevsShyAJdNkfNzflSmFhsSvxUhCbEcJSs7FGq7d6T4Vvbh4JenVd2ZwyWkXsUBF1diIgOt1uhozz7i9GBQx8aOcwF9ns1vzO8HU92Of95rD5xc-MDWqg0E-b-R-Kygwdz5Zm1Gb4ZQHihiJAHk0xpqVcx0Y6ucnCdYFYKmy0os8-SuyCfN7-6t4wwjKD_zG7mj0u1B_RgFmIe1auyGdJ3LSrYG5T0APTDFYAwAsQe_vzbQ4z963m9A9Z8Et1ZfBrIF9mxpynMMx0SohrxVuB9YXVM5VPrR-b_b180BIIHaiVvD_vCC4ndijbOlLrsERZfTO9z9ApU1JyBjPhM4rSaL_4914H1lpkzNB5oJYr2B4JUF7Z80lymsiy1exhEwLTsSe6NK417lJ8zGu4Yw4o4ECR3w-D2BDbL_PFONwbwYq3aF43XwvUO9-i0JVf1DZOAh0obn2iV2aSy0TuE78fs27lNU4qig_cIayypA6aoDn-UwZhkOyP0DypAuh63PSevs44ZUjo93DoNCKbRS8QMWm3KiX5-mknYlg-yfOgjFKJOb5-zTFPomg2eVFpAe1L9TeKL7rUp7mU=w886-h1326-no
10	https://lh3.googleusercontent.com/5TQkz5kVUXqPSXNScq9i5CFOdVmE62q8733bYMfdp1BE-aVibWNv1P8l08PGiBrbyWktCVjQf1XsGCTpewo1rIRJ0AYsycmV6-O1tnlqgmQ_HJhOQtQtfRh36o6q8YHmlTbEBhTm-sxmVGHEyCGVj-1s2A1u3ZSxaBW4SOCznZ15tfmntw1dlHQ6An_TmOwRkwKDY_XZbHmhTcRia72JWplcWqOTX9YezDXBlZaAkx7rvGU-Ky6wFMDk8dgFW0qVXDf6LO19xJ3wjHCSjOsoqhlkyqZin8ecGY4JRwC6F7M59ywrOag1BOW2Usd--sTe3aE1SEHdzLrABCRAFtV35SRq_e12ZWtGjDpq-Ql8_bJgKsbxTWL3bmDj3QHmArDeKFUnR1t3chGvuUjT0LCSohOG3qZPu8xWE0uMabxOlhPFFbiX2mi7YTiX7lBRMsKuvgGbL_0mgJwW8MBOWT7Ro6HgQb_1FFd4FmACQTfBKFnIBLBQJqXOWb7KxXYsJmmjrzKLa4QGFhyrgXMG09lZU4AcfopbnQrA0cJ4OdQLgQpxV6_1vdhGGYhytJTETUlqnMZmBec9SULPkRKyq39noM5Oaora31Y=w1988-h1326-no
11	https://lh3.googleusercontent.com/kenokQl65Cwumqre8hFnDbNGLIDPFkGyzNwrWUcvAQ9ly0HN1ES1Yp3Y-ZHzaD1Ksc_02JIDPD4wTn2lmsvuzHJOFCpfTtEOClhiG9SyuQLLQM1RtbpJKxgBEV0GQrtZ2OTVeSZvAYsxj8xxfPIMgdH3cd7rXqbU6e3laoW9tit20gPuGpCF8jVaNK9AdCmmS4Hyuz6xdmn90DKZQGtNHkjc9XoH34ncIalrY4qNKpiBOT0XFO45VATmhslmJIyw8LyNK5iYrrH4I8ywUdwC3ULyD4nlf1bG5Ss89xn8Uy4-5vSnbtAqYy9PG74QJBiXDrn-4XPIoNVah5lV6Wo_wFR3xN9poAaLn2NYI5D20SgzVxZR57_sKzwv-gSjKoR7LURZOdNOZ673g1W8dW3mIQeV21QMsyMCg-D0oUyA3qO8eUzkzVRH5y-VYCiGsivc96ndLbaF_-oDNAvXYRRaUFNHFz4FcIfhHzjkuIBy3P75xGR573dSRdq7sLple2ABiaRFjAKVIT0rNX5WlQPIcfXw_GyStcqWUl23ms9gke-9kX55fSOZoFAxUgG6iYriwZc4b0c3JBmtf9EyT_qGfTsGo2o2Ulk=w1988-h1326-no
12	https://lh3.googleusercontent.com/aqk8-BqXC3ebj4GVvbeLUlbdX5cgr86xHrxIyd3h0Tm8aFDTi2QrOKNlnuX91n-OlYf42wooAi-e9oKxS6RgQ7R7santDBI2NGUgoStfWOl1MrkB3pnrbaFKysZO6sDxhtEggJmbH_46C-nhwkgzr8oisV7sRz9TMcV3LU5igrCUBfR5aBn8V_68ZNhgbl7r8OChA9VS8A0ewzEtJkgYUd9h32jtBtlMwJh6vnCo_InRCSbvVMpH5uFUg_82QwxtL7RXE5Dtwx35ccGTtjSg0i_e5d8dTEWU0nRuE0vi9TRJEUvF3nHhVwRZe0jL2PvmoCwunQx1onyA60zKlyBO9FvvinqUJIH1htQaKDtDFR22j1CMI1_stzB0Oe0a-n5eQo03Xy7ctQNtCTHkXAATXq98m6Tkel_G0pkZZq129c7_gC7i9wcZ7fdnnGrvss015ej3fxiQJwFICp9UPNoCUTWdEv15irQHjvFAfNZTPSsJsq0I5Y7Q-XZOeFcZQo0mZEfqXVM05R0bCvE1_sFov5khxgFLCaFZrB2MPKQSSAe-6uYRCgAj5KOW4ccrQ7a36RvnFwt6TK7D5q_ntOarEOa1UhMjJY8=w1168-h779-no
19	https://lh3.googleusercontent.com/jn6W_Zt55MBDK5c15KTr14i6HldLApfCRmgQGhYs1wStP_SoH2YjZ4iY3-a67iPC5pcgtnpVdSfVO2M5vsaE2NwDqxZSIfTk317eUpO52NdtFtEUO_9QiWo-rlbuPU2foawzbRcBg09NN0g_Oy3RX4JcIg6siBhLTZryRxCmWOio_-sLP_Q4LFL1VoBzMjyw8UGfWns2lEWfcRu5lS86aRp43eyblDRdWisaUjC_yeQFnnx2wO5NfkxKrcnCjTWLohZSZqavvIyWESfN3870xBiwcPl2U_ZZattHaP7QtPmBCSoKFH-YNxPCi8rEQXL8W4E_rrk3JsYKzWjxTzOlnZ0ZY9tg4VOA-uhyHoYBG__fCGlHT8gDZG6llx6W3Ukpn3btPHa1n3IwH9pG04MDWoL2Ja1CxPPY7XcNL8SkDc6Zq0QyJzPS6Sibgl-jpPeuMJCJOj_J-vY8kXOz71yDHxo5_KiH99scKBJvoUNRBaIH4v-MsTj7d1GfCRFW7BHttmQb0toTqwQvCfG-BMGn2sMzE3PUa_Kp9qTPbv-RGbqu9xg3hnnPC_0fw7-EPZ8ygV4IJMvGRNPm6ijEYaHiG3pB4v1FE0g=w1168-h779-no
26	https://lh3.googleusercontent.com/OCJHvmLYkVExWEWOd9CW084Y1cOx98Udou50ZclqCqX2Hxh64ACfVtE3NrcpD_VmAKn6r_1cB6-FtsniUyCVkAA220FdgIGQ3RqmJqFyxon7MqRdmLqUQiBPNBYFWL6TXDcr0rnETiGBjlHpOK7fFUFnMXKThbEHz29kcLcR-u-m2lTgdNghaJqdi-eg0aVrcskLR7nJ5SEhK_3-HRK6ykEOvkwc2PLYRZPAki6KwP8UWs9HCVHgqNaXie47-WwIRPd1pC-4eBA0CSaMS6i_nT_MpFF-ExjTJu8--K14ETqbAPnJ6YeD82_f5wl22GvbeS2RERN10QPeIVP0ITeBJAeD6P38hdFjMasuoJK1CbEsLsdwoA8ykWOuaZAkkYmvlopXkQKEFmOFFqeDPGlg8NDoynronka52N6JJHseityxNXfIsQcIZXIk8WLiba4149oSTo-iiC6A9ZK35Pyhx8LIQDh8_eFKddZb2yPlyTkXqzGO_D1UmHNDRNx9P2eRbVDw3Xdx9qWYJB7PcndCTUGydE-QsRzdz8P6kORC5r56qI8RdGlHtvGjyleGzs66Q-Y4215BrNK8aYJVYSkHDCWY0yXyx68=w1168-h779-no
32	https://lh3.googleusercontent.com/3P8qLYNrvlR0y68cAbSSuuL1yGF8Zsi_Pccr2FgyN443wl9XZENTV1Q1KoZuPOd3auv-Vcg0FGMrRr3vUGIZtnnPAzDdPGH3J2JJ6NzIJI6nnuQ_AZFDGkJv16HcNy1jtXIcofy5hizK5yBdxFyaD5IHgPC_9z81rkaMN1G1pGbSaGibqgTHHcr5QQjTYlOM-bIb-cFSMJcHmV8bEX0gTdNo3FEBgLlDXxar_caoKlOCqiLH34K0T8A4i07lTseELBoDBnNjU4lqlhEwFi93fZEl55WGBVZV8yS2rWXO70GcU8oLyynqvkv_pxL1DvyKR2xHl811adVlZ2GhJ6KYNYyPfyBDYi24N4LciLxo_2BLV_7il99QlMsuMsQwPuTWwGP6_mF8S5GUUjoM08NlnS-1WILYhBPeNChHuQqUw7fhW1EzMHeGpwPQIyaUy6yV5KyborcFZ-kf1ENFfoqCyaK6cGtOd8IxpjPEyq9pQtpV7hQUm5pIO4pgpjtxZG8rc8emwzCDrBHWqEqd4MBLAGGZFkglL3zH50dKhahFgMJgyucLkMWFRrz7DXvnVPND2OV6Noj7zt9sKO4w9a6i8vk6_weBsa0=w1168-h779-no
53	https://lh3.googleusercontent.com/zuAnEyuQ17PsAo4KAbpYy7y4_-qyJspeknB0Xi-wHwg-Wr8zeL7ayGZc01za_Y4_26LOsRTin3X0OkrcbfOtLbduX4bLZ5O6tzYruzS7SIKxzmRUzQBTk-tGv6kSxxxBvsOAOtqTCrBPvsqQ-aWNqP142rlb0VvTgNZJOIdeD89Rot-c9IAjx-2AZW6BglpgSQ0YWUVJKVfFcb8nPsEuRRs8cEDZAlM5n9njagrJjCOKb-5k96aSvsAxh-lYjdZSJLotmTq6yc4IEz4HWpbmLIUUnUcw4QkpVILbe7lePdoq50Y3_2ZA_ReRZB69z6WhR5hBcfPFtItXjeo_WEAHOPcjRLLXEmukPn8eGV0iDQul3DpvZc8gupRCdGIwsU_W12VYwRq8dQcfawFlIRecOKWDDnVOvSGOknDXa6_Zz-3PEKjsL2JT6cN7H3zXBR2LMBAeATW944VHHS98LBCtkpFpbb9v6v5fVkgH86--NXmgxMCU64LsvD8idy8OZelhrDQZKcv36YrCmdZbTZSKUXD9Z13uLkTSef52KvHAb_3yqwLyJBY-oGdXdPkl9WH-xNyra3-WHU0o3Y2nk-kL1FTUaqjV8fY=w1168-h779-no
57	https://lh3.googleusercontent.com/EzqW_SDQXa6XWJrF5iwdyKn1hWJWdbDgCx0iElzWixGAsPtViM4JwbQ_E9ysgOP1lrfZLyZhgpuBvq7EdSat3s42TPy5nXT7kZeKsWvoyE0-7I4WYaUmR5NLVismX2FpmbySkUVPk0svvSS6j8W80cuU6PidoamvHyQdJ_mAxgOL3sQq_sxP57R3KtYBKjQV9Sra_sgFTbMUWneY319IP2BrrmJOts-MG7jZJbTBJnmaV2lyfcOZ92FYtwj-EU16M2pfOauPIfC7GH_OyZ2NsVzniT1yMWK3gGC0B_CSBWkG1D7MCy5vHpzG73sjcAcJ6u46olxaSEdcCgx7sjqwO5ELEfvYiBHLW1rVS-SkifkBsWi6IvlUyqLY-Ph41XPdkawHQsGyRN2nhZmmsXBV6m19dH0FuqtTt7CQBFkOft2L3yZ6LD53ZJDz4sbKfbRSM9xBYuAAUBBiZyBKT2ga5MlInKIb7XvLgoTxrvk_HDBvU7vqLcXS04iQrjBknqIRN9Q4JW_KfretkMV50BX84g8Snc2ERGPHm9Bx8bess9WaO_leUxxn2yCuicHLG5fUncxXCMjf3dGMB9tPjV2MaSdOwRDe4sM=w1168-h779-no
67	https://lh3.googleusercontent.com/KUjP9C9ERfGyMG-pSEoCI18Z75fAPGOfyiqadix6LhiGUYzG6FtaRPjYGO69F2YVCD7d8z0jQreY9N_VM3x_XzNs_PKi-F1M2M24XwuNtwIqGBWb2OjjRkixakxX_cfd8WcjfbWsABIrUX74kTFRQLyfzuw1PO8qArFUjpm6ehsOK5vWyDpZEjPBVQETmgfniW1W4XUjA5miSBpGD35TYoiOacnvzVp3KKRrJIkLT7pw1ygVi9OiuDwTkdJOVHuCMfMnTVzFw6HpBBMZGjl-FSIIJ2IpjbtTPwN5_L6IYur9uBhhhT7av9CNJSEko_TENhK0mBZcm4IyyllmkH_sNom4Q6_-1ghG0K_f_zZBFZRA_s4TJvGMTCyKCsePMQmcN4-RC_r_E7JX7ujRakiEsgGjeENfPdrg3n5Iro5LBWfQvJS0Zfdaa92g0_o4UBiHS4MXq15ZW1FjEmDzVqdRbNY0vX6__vo-x1TYK777wy8NISudtrVxrf7Yv3pRQRAOgZ8d4QNWjktYb4TfOcfpv9svY9argOJDEF3VJfRskg8q5D79JDQPfKu_LqT84tmMGmAKUNlwEDuPCBBqwk92CF9NYMG5ZnI=w1124-h779-no
72	https://lh3.googleusercontent.com/nMTNKcSdbYr5NRuNloa_BDEnxijcvnr46K_0fFyad17KhnJ1XvJmFnh9AbyV_L22Iw6uC3POLYIEdN1YkfAsYFwz27MEHohiOW8aFC23l9z_55Ox0X4kv8lkx4UQm4ZiF7QeRANPUDQiP5_uu2dPdYDjmikJwftAD9UKfdgkyPpx5Aq-IedFC5tC5krqWn2r6oz6Dktgk0a5JCfAdWS6yExSnJr53feupp34JbG_HsA_KRtKF1_Yndv-Am3or5t12-cZL4DR35yDNGT4rvK8qkL4qswd6WpGRML98Tfpvz2zxocevcM1iKrVqinMgYmHimvQ3dRmFfO5hqsXdE-BnOqO_-BWEK1kSqEJ-4IV8EPr6-l3vPjMxu6MZbnN_oZ_AvRBCNtd71dRZIUuLho0BzvgUQGNKl736kV07Ahknp1lkyb_1M649qAZcGgTQAnn9k1hp96CYiOAd06ZOykZ-wePIIFsewiEejdBJp_Oaso7iBUCFjbTJmPzaK77xy86NHS1Cc0acKai1Iqc3Ur1DbYxh1An8by9lIU2uo4L3Wv75pnuohsRSZj1jVMJYPQIOyi4sSMg8uzD6EdMy76NJ8rQgVTyw4E=w1168-h779-no
79	https://lh3.googleusercontent.com/uw3xk4GfBEm4bS4ZA1qZxlNPmo2xgh554sChVcROhnAOAXHTFnWydxgqdsCmKKlxNK1nu55337gq-7-KQNU0xgE3ouGK94AM1P9oR2AM306WvxPYqsu9bjb12PpXJpeMZoU8cQ6PKCtLYE5_fKzMLlredJ2rjtXuUfqk1FrIjHgz7btR3IiHmtNYjttHPkhMPQPjQ6D9NRIRnYWq-GPrVbBeZuoDmaQ1nNtp5lcKrLH7IOVLnFCf0_bKtmbqJQwPzzXze6Srw51tRSDjYkwYIO9zp7ta_tkjfC9sdCYKkXsf2hQr5gp85G_r8nwxWZ5u2wTYDpCSzOxlt_U_2SE2tvMAvAHIZorGjQF7UaQ7iwS9QRdSUsBlVv1bTkdTtCW6x34Kb95gJ2bkrFaYhN5MwIiXeLcI6_EfJnJyEJoHN14RKINq0tpm_Uv8KxPPDwGYu4_3cSRO8duEsFxqOa5z94Mfeb1RKuwDdtyaDVM1yic_TUWRQJHjIrEkvs09ypSCJGQXO3nfJ-0tgwxZvMN2yulUQjALdsCbH1db95cufEefrSyhgkpjSHoJMPgMMnCrgjrmQwv9x3J7obrLhAaSUpBedFGIjXk=w1168-h779-no
13	https://lh3.googleusercontent.com/ZVifVnfH8TrJf5LAC7n1Pl0TyNyK9U73v3Ib3q0DeAj37v_6c7XfED7Gs1yp5TKTp0goIIFI-LFs5ZjaGNLYfJ3O469AncXpctnJZb4yuZCJV35LHy24KgD-GIkJKvzFRr3TiEfPZGK0F_vJ5Db4wWd-ggbLwZydtCYX70aSChKdQ9jJLP1GZjlhJ7URkJF26zGhHLPq4GEfqeMYUEaYy8KOUS3HraRW0qED45_RrP75M15MbKBjBNS7kfo-_4tD5S7aNZTwLct2agU5JIzurr4jcz1O2HV3-vtl76kPcPNXmVhLq0ETk-6MYrI6jD13MJ1hKGlCU9qtGsPQkTUdYp7n3otjyx3DG1RUEWSsbIWAJ9qyv2LRkCkR7IYkJ-Ooho9DeOaIxv6ZShcHdOBrfI0o1RbKoy0wF2M3c1gkzXE-JPpD5RIp0iGkgRnswi_kJj0mAfAQgWzmLQTHDVaKSDwrx3aBM4qbf99eqeCUvOBZSH3zCEBkeyNN1Zn61QUqe55U5V9XquCzAfpLneklYxl9928wWFIFHwji6kiNTQO5zQ8XCLQCCux6fsHBr191Y1H7lUMoZZagqLmdTsKV5a3DFIVJP-0=w1168-h779-no
14	https://lh3.googleusercontent.com/ighMRynCiIaSzOBoy56ZL47CbljPZLw9VaJCneDeakyNMXaFFYUtmhgIy3vAXZNqMSkZez1WV7m5YuFVOqE8xOGPbXO7ft1ZS7_0a4MJzA9FtsZwtqPqEDNppElFUPgNazRlqNJEZgi8wBNzAuQ6KDlp3nP3vvVSz5XPTsMHF5ffhwoFcN6LItPbnBPeWFfrkCtBIQVYJWFj114EsH6bF3P-41EDxTTBomXOafxLPgjwFav2XXmGH-4poq0CsYrnLzZK6NDSzyrtqC0dLt2dbZ1qFgYV2ifibr8wvPH4zb3VfPRWq-lyBjtAzkqykFe2118AkCEVdC3t564WA6cyEKBQF6Ig9M53CMWn3ZUfeNJXCxt6qHTcJu_OYTwloqZWAp3kkCYCNwgEfNNCqBS7OumjwazXzJiNzm-xANBK4DKViJ0Xa2tnYbJEzZhQplTIAjs5p25N1fQpsSAtDIgLB0sIcHui9KuJfEvqxu3PgpU3LZVfcMm1Ef4za1vXNyvU0Yil3gV0Ba4YbGu2WA6ParCqSWLoaW0nW0-wyCuQwAJdD4yVnWc8zSCKOkQVai2ox4wLsc7rMtK0BpNEEbjyLhw4LgGbLqs=w430-h298-no
15	https://lh3.googleusercontent.com/SlH-z8oaMloKFImkupn1SV7mHQRmQSIwNR5m36YaKkKxgWg4KR_1VVBE9zGUoK5kHp-qU91OjxNETHldOx6P66Ep1BH7WYwCxIi8nnrzxEdPD8xUcg1f0EsKyQgavdqa1OFdT4IWYht95J9SGTA6JxGjnySfFoa2PVxS9SOS2vQOC59dF5ekywlHNnuy47Y8vuHhA29icUh3Pl-r6AwYGT8VrrEh9izdwyNkc0P1pftBNcTrpRvoM9CN1HZEZj9LBrUigJPDlbViwdBpwhUAcUeiwrkYZ2VKqr9w9o0o4Moic6vqtqdPnVh4NEPB3mjcg75JQJb1HB2g92--Ao3cLpUOXjxWF-VXM-0mqIr7v1_N-J_o6vquxcrk7dyZJPT4xWYNqIxi-Xj99O9fxPkhOzJn9-gomoCtvi_2XYCECZ--leotrwXd-cL_l_rjv6vU531YQTzYE7W_WSO_tqX3Wmblp1czvnSXGlmnSHl_jynsoHB_rcAU8lL8Q1kLANW79Tna78ntZbt3Srg4CGUkku91XdHeyjGOZooEHycqrmJOvgbVnSLjDG7qq5IeT983ng6zgXJbA8Va5V74dRr8v9DyvcUVAAw=w1168-h779-no
20	https://lh3.googleusercontent.com/N0tag0PruuUDFaT4SUjR0pkU1ACwAiTqXaB4nHnIaZZrC13ysButhnmHFC7myZ_gPkXM3jWCdAfVqd_zXPNF9j0XXjLkDSug9TASv46B3Ft0P6iQkaTZ-t4mK8zmJxeaujKyPNkj5ZiFfu_hfNwAMn_y2m3e_yaRnK9X41gVihXwlZ4u3Gkn1grm2JPGuo2qGt6qa35ctXh3Mu8yjbTMKxSukO8BWob-F_Rwm4jMIvjYpvtnUQ1hGoj8cUb-hexXIooF_ecwKb9cg16wC5Dj1PBdOBnkAk05l_F1gN7s5-dObuaW1KjlyiLJHqRNSqZcFHQu2jM6ltXxTFTl-2v9KEwrsH-ykeek4X_XgA_tghRr7lWhOnqq5G7km79Z1A9VeGZmCQHN5LSgAydlu06pEiavYxZIQSgVFRw4SVjsC85SpldCucM3KFRun9l5SSnVIMZaACyY5CiS3UpqkuOgqlevU8FWUeHV9bw5_Bnr0xTPbOl4o0bjJ_2okwk0T_Y1s9EVah93Lmy9HMuV5o7FMfmETUjUKygYkAWdyYry_abM7F0LkzsMD_pMrUWZ4jxwHA1GNy9cjODNtYZanRJELk_09O1JlMo=w440-h294-no
21	https://lh3.googleusercontent.com/sdomEmS2jmzkRLb79WONl6Y7UYYKcH6mklcQWQOVgHjZolPUt33MufYTKdqR-QPKvnKfs3zLwITqK06XvyCrpS326TBZn2K_2mWDt4RY6fjWlHLkUX5Koz3bi55j5x9uqQyRA5j2FEij_d3lX8PuU68KXczauu-bdKXcu5tRD1vyz1Zo4i2CC_tU3-49wB7wDXXBcibXrvvbeb4jeJfmJawTgCUORuzP6Ao94JF0To-GJ80_o9fvACCNGoyRyKtr80rm57BYB1dzPOOzN2tvMtyr0H4Szui22fakhIDALHZiTP8RT9ZmlB-xLkSSd5UO__m8iakxXwoKzz_0lmQYNzcCCjZodIohO-MeEbhsDaKJDYgX_696pFqwMBeRDhHzZvqmChoxhl0SjII1lcC84p-4QLt86uk-kMXaWpN0nFBiirujrbYybUNxuKi__cWn1BpIF1UaJ9Q60PIYLLBfLv-zSioZ8mrzAud2bPaq4DYTjjk0MN6EKnNEvcRR0OSV8r3z9vNkSV-efPHxDTxoIpPLnwOjEWpE5HRB1usIp1szL37QTZ_DFIBdiPQdt0G7ZpFDd2z6EedTQCEFbHcPU-r1PMKKW7w=w1168-h779-no
27	https://lh3.googleusercontent.com/hFfLev20v_KwvDQl0xDOEYqZD6dLEabFuZ7qt-3rGkVZjC5roPcFmW4LT_htfBeb7pPVWky92wjtIoS6pl3nxe4nFgM7fxn3_H8-sKKpLRRmeoa-j1b4ukXNFn-UWAnQ_oh7U86YUImMQZ2rLYqVgoNE_ZSVSOXikApe2Yd0vnqwxmDCfUEVrbe78YwXHesn9uVx9p5vwAyaCsXtlnAJmAzWuQHf0FsF2rugVrB00JA9Bj8tYj2QuCiVYP5yKElI4Ye0oU6MV_a3a0lYLLS97ZeUW7CXcYYTQuiKB3Hghk9veXYfRa8nyqDqzedRcmf-5Prhl-BcMeWFPqM3fj3L9f6lRSXZ061PUWLeSIqmQnM9zn2_-DtqBP9pI701LEksJVY1y6w6qQ-FLiAsmtvflvgD6ETwtnveKykXSb1134xWvU69sEcQ2aYZg1p063Sm02sGn10Wtf7MHYtsh6uS7dJcLWNmndzY7byt6A13OPxapOLmr-ispeypNpqM5oACCqLhrc0vBkIOLdUfBLRNimmgBw4Fa7l2X7RPxc39dJVcdO-LbZV5lXkQR0928JhfMqjOLjnK4pZKWK6C4PiKhVWrvnltOTY=w1168-h779-no
28	https://lh3.googleusercontent.com/O3VY2BbdCtsFD3O1dlzFJTn62drdl6cfLdIlRRFEhMnKCA_nhvarJq1LTK5HZCf2EbUGuPB2EJyWjYgBkCXchFXlgD0TsDPmQ7sI3wV2Asqn7AVhhwvi23jTI9uoDz8Qxz3IzJsL8w7MeHDQQBOmhku8Qsp1uJBZMMP8Co99GmCeVo03uSk-x5dP2fkkPcENX7pYaoozZzLahveYEjUbikaxdCOHzO0oZIp1LOJzwznD8F49Rzy3UeMwD-bNlEaBd9GJuyQPuRWD5cSAFItiIgi0lMfGYSiYZPNrRV-B3i4wel-9R87TxqIwUe8OzLyuG-jG00JSk7FljMG9CSzoeO9YY8uqpdEVf_b2mOS5-Og1fKzRQB-l6_F_hvtSz4y0ce8I9l5FbL-wP7Iq-5HqYmcjzAznpq8VjZEC-zpEOSpwFLHbhWVz0pq6trNKqQyF1JfXsdQSi96YDPNPOVtwuJyQ4XwBXe5LciyLuEB6ykasTfi6nCXeRAnjSvMJn4x9EWd4dW5WwqRfooZWaLP3zNQ-gPkyKejNrsDmvqF_SqLLHJniU-0VVXVUtTR4adIsETBwD5oOD_Ax8hxkTbwM-xgax889Jpk=w1168-h779-no
30	https://lh3.googleusercontent.com/n0QuUJOpmwsKoZ7yRNh2neS-JtZhMKLqAJMxTFGELwmFm7RPDoFCBAKmPz7g25mY1njOUYECpxGdmoRV8XVMCG-mMSpxQyXur9ac6IsK4yl1P9zfJ2OXmsjqQZmCX1MnljvlODMMUn029_4gCuu6dAaiVsdE6Hy_TRgRLG5cDxuCI3aZjbxwwxKOXN9s7Yg75rLrq-BusYMnyvReI5aFO3S-RIhJXqumSVQ3WsbUK_AxZ2hPzK9GyLWGb2rWGeoQ7XGm3uhvGbPoqIzB4HnCDCI_Cf1xwtSY3W_12XZzCZYf2sKYuA1JbbwfHQF58okYA_0pK2QKoQyOTDttZZrMrHNGMN15Uzz0oY1kebXGu8ABqyiso0_CSqWrBUaTnXIeJ1jIguZhuEK0D7hi3DbBoP2bEqA3CZ2mtACeg29Otkw16iwd7uZW1prgBugb6jeD9Og9HkvTnvtR32Nijy0sjfpQ5R2wR4gZsR7xPNeqBxqPti8Dfczq4GRdQ8WiZEo_vE5EyDNUYI6-iDNgtAAWCRetQpE3s3p9r1fRSHyvzFrG88aoiNQm-xQ8feXKkJrztTwNzPWIkRknVBW59tgWaxCzDqmdKeY=w1168-h779-no
35	https://lh3.googleusercontent.com/DpC8MHOyHrSSI5Pv-4OOBaHYibLKXHkGMoUkWaOeC7-wJLx9JMFBB2iDX-H5dKmU2UYyWbNoWMnTrYFiQXYVL5OHneOUELuY4lMdUGgACNkXLD7aj-dMrEe32nTg8HzQx7NEkTl9uQjFdJ-vuLqJD8cBJQhz7rpNzyN24huynTGhnBhaX6cvBc1FW2QwytofQsypgYVg7nKBwAGkraDUWfdN5LsUkMXm3tC39qSqtWH3IWcRiz7aGEdHzl6oJb636_RWoyZSIDh0gCCXxQeJuJZXZ2yAdKy19fWT-wGhwpwFICOXY77sl1hXnPpbpURb8u8fTIp9m_QHdBhVwCUCGI-0kmSOoEBbEPktPEo-4X-pViTxobfm9hRYdb1xPPwfTTA4VKSAQw_vOUBFv-wHMbNUcxfNktF4_a7DKNnkhotgtIL3hqCviAc_RVgnCaE8d17HjGvEF358RsWtbbCxXmYuAfr0BTLv-Qg7Py7cNyLNS__o4RpHKn1NvIV1KBGWf4vT4pGg-fHcYk4QFx1v_4v_YVMqkdxOkYplKkTdecKRsGPzJ1Sl5yqfMsW_fhaNcZsFi-wKcWFIeaRH_I0rXQ9fHKCXYuc=w1168-h779-no
36	https://lh3.googleusercontent.com/BRnl1Z7Q4BO356WYxJCUFwL33GYFC0-Z3KjprdXFsDzaXqi-KtbKNPEmhEPvBpdynVtjBgBVbq0zN9M2AdbxVsGn-lOX6mEtKdyKPrvhqH0MN5wunnz8oR6gPjbZ75r2po1nhT9sP_lFqYZtuPV3wUm89crpTjJzJyHGhcjuYCX_b4zcgBFbNjqJiCVZbbsdn3Fh_vX-fFB-4B9W3EF0wPNhxvJtIAy9Cjeo_WfsZTqOEyO6C6unWNeEpmlTyvLJS8DjXIgsyC6jQH1TQlU-4bcOdM0LFr3s6kvIM_9D_q39b4yMDBYwlDOVNiwHDV0RpqojywJpFNZmpe5GDuJbt6Xv4dWYLEbggEYhylayhV08zAf0iU0nLD7onCLl3WdUBz2aVljW2LY4XjsF95Mxs_mUbgxi_Xst49AzDfntM0goSByxsDxnSucrl37LF1sIFLoL1znbOWOmsgegZ7UQub287beVIWP50yISWTXf2-PpdD4-BvmU7S6YKNHxyZhY4xBJBLVT_9fSUqj5n3vlPeC6rg9Yj-1NZjK4iSSJxYvPHlVtNcqFrsBAvVEhMszGih6FEqSLyaByXQdLhX6QnCFh7O0mZMQ=w1168-h779-no
40	https://lh3.googleusercontent.com/MZyVgf5C7SuBCfo0OYPc4AQdyeZRbG20N6lqFwPSv7qjbjokTJx2sahSIE5K3M27_un6_mmFTYJgyZDvEZWYNBxQ1RgXhRe-zgEDOIQeD_PrLr3THRZPDZ4yd5kN4L_kSdbHcSGQ-M3TwlTrvt8NPHYMXDRTwNK9CX-587MmXb8oRYIy-hnAFYDKQy9g183dKo0zlprcTV-PVjY4720t-jtru1vIGSZ4QANZn6PwT0oSG-6xuDqAXR6rdwf81p-jOtBhwywj53_O-5J6Byxly7SvVJt21EaN5mrSTwNtftyPFCBQzvuw_-d1wJ2GsNgSNz7zwJd9N4E3C1r6x5ZIYWNN1CI1PPfxU9cKwQ9atNGabFpveX66T3tfAT4i6vzIl0jHttKQHc2MXQll-7vSJlN850LLfZaShGIeJhREt6zIs2nmBAnLJZirvgNno8LO07-hR7F4P5JtA596OyaOayEd0tlSBqf0iDuRulOTEDNuWtK5gkgv-ITPop29b_ssK4ZUekfCElcPAnEkC41PP3x01R9IhxSVW_DD-Ph_VMOauSaQlDjgslCslE2lhyCLAtIRKM22Q5zxEHZwnzeWDARrOz44kSU=w1168-h779-no
16	https://lh3.googleusercontent.com/cvUKMkUQ4SvO94pNmlFhWsbvFJrl7PsXf9YRFSnpPB1FRNzfWCnj7HIQWwRZ4k07cqFzijuzJhTs5RpsX1e8i1E1G6NLnRuApfWBggLEmjxkTcYZAX4Zrcg1oizYAmYXxc4JsP56V6CFc_eZzCIKZ-HOAO9oKAOQXrRfh8cfia3Ntn-HwjsGmN1RApR4jqPULQ1xh2kFrZgoYJc019NlziyYgi1Kn4fxPLvVPcjcH2jNf1iiX4-up_D32PChSx6bTZlm8_83pzSLWaut7vQDXnnYZ516toiEnNR8KOC3wTlw2ndj3dSbY15qe_drmH4zZ9bEB12n4ByYM05FmrdHZcMl93Jcrv4hGBHDb0CeZsxi4kxLhxnMDbYFQqT2GQw443Zy5ybDT81ZpmSm1JIigeV9dyeDJw4IF_IObTzdNQhpgMDhAovIvFO5K1zLP-E4KnK98mYz8dQyGBcM7DqPIKJaxMJMZVlD1Ey9_oQVCWs3RmyTPm1oTUOF1vmDUbqzYHetPZMMR3U4J1HenR4bq_yi9QbDRMTqLTB0zPqeGwqQLgJpa2KNwhdFLgnbAIsJr_VzrOBfBlKiR5PRaOrOInQ4oDzINZU=w1200-h801-no
23	https://lh3.googleusercontent.com/nSJzgrk5DtiSfMbPtBlLFT6dKg4It-BTkPWxeF8q_fwhYJ7gfwPAKYkIxhmc183GfotfcU8mC52ErYKiVvkcoZQhEQLiGJR6lstUsJguPsH6FbF8i7-t_RQKd11aMGdvbjzWw6jEs4HEd9lsgebsWd5JQ7NyUsIII18dplK97oyexYSwjtwoHRdDQdB46cnZXFRdNSMPD4PBJwyYUrRDR7M-HnaxZK_IqEaDfUFaAejxYEagpBI1PHy6M4cJs-D5QPKET2RjE53_uv_b98RUwQqPwDgk1b6-0UfYgqxwVMCIIUzRM44gzttZO4uC7aKQQCnKeRsf5VYbDiK7tFgAQCr-CeIB7LB9czRy9jOyrWZiFtVjqfvMKesS9uP77uypomPoOMEPRWOygesRtiaBBxnNJlW0mPxZlZFhkTsHJzFlvbtklMBy_iSM8F-maBrUKnCZfkYPn0F_fOALNxd4-SUsXHoapXHcNOf9w8DsCvggIil8tGdQBrMgZuJ7isMIJs5eSP4j8YVOt-Go_TTDqQRkeolCc8nrhdbaLDhq180Hr-kc6Ungf4EPPu2vt8ySixBeNQq8aED64nE5DzGD1Z8ifpk-T8A=w1200-h801-no
29	https://lh3.googleusercontent.com/DGXf3dKYFYNyyPlKsXGAkW9ophsy58oSfKJZ36NizirbRmRIfnh_X7W1arPiOBEUnq612ibeMXn3x1DBq8ecDp9y3YKiAf3LXl3-49uk0NyGvZGV44tvhHuFORI3Z_tMGA0gkXSqZV9onI5Xq7kopVVl3D8e5OyymSziufVc7i1I_G3zLVynPINz-GPVZlEwVJhPS8vBp9WOQtHfkeH8ZOiRisX8nCSzqGZQLeOO8ZJy0K-QcBxBUNf3s4hBeHSKDH83R_gKCUAlGogP0052RlMx_C75kb50E0AHvFsi4etOsc15dZ903w428pj_GYuYfy9xBHEcL2y72mtGDPERowFbnwJTeBH2y7cf_yXyLBzuiS3ExeSAN0xfOLGIPsjjHkN36eVqx0J-YBzfnj4iSkNNidItfWB6F0KnY-Q0zLtjww08VbPPwCgIpNCj0tZis_12w1Yzxq2nfC87Rph43z4jmvvhIHlEx_EuM68a6lbvWeZzF1Vvl75D4GFWbw6oXrYicEDlh3yFG2YO43WHfaMvZM9WTmJgIvcGnrmdlphkZflLs-M2NxXFd6xD4iRuJ04WYsX5iom9I54ceDgIK1llmgSydGg=w1200-h801-no
51	https://lh3.googleusercontent.com/UmmIh9ItgKckFdw3-aq_VMJoZASe2jqt2gazQGtE-3L0rBBUZDr0QtVOVQEOp46MsRTfImVYtw28CfZss_E-lWK5qH-TM0d1Ucfm4cHCO3Lyw54ADE1WK1Gj0XIGPa79PC56tzYZHaq0aJT2sHy-UVEBareMuRZcGE65gjTRMlz9rF_5WJRkRaglm-9MeUAyIXgWoLAgqM8Tg1yKKYZVwbWm9VB2Wppusi8m_0FIVenoFmu5k2nj-c3viUTNXMvkJ2mCWJ-rrCVzEx7HLSFdIOsR7OkHXCpPHXGWc9nLSVV-mnLJ12_m9u7d4IymaMO4bdnTAWNUn18Yk3FcAab_2KEDsCgRq0Z3KSebWAsJJnepDeBgJU0Z6RMulS7QXC8MVTk5j-GL0dVQ1D9UYi66DbhdUrAS1wd9AqyFZ4pxX6bsTFjUdiUhUDNBbtj48nMnotFQ0PjXD9ZEO3446rrgun7Kwn3xFYllHGQeEZWi3xv7iMIQLAkaQ-G-96PMNxYAYsPHZ4bmHB5sYJXWjBZZEoxeqtitVkMixPCsn42XDWptGbm_8tDkgx0_xd7hnR4VSXOLDm8ALGMgslNSQYhYemmGImY4aH0=w1168-h779-no
55	https://lh3.googleusercontent.com/ZgeeUvwWJIlbzV26I2n-fgKVNtTiZbHDf5sIXREruUnp5-Oj9UX3Z-HKqz0FuifxYoOhRzfWlbPBPCm2bPq863-c6KeqHreeWYE6NqsITsE4M2qLkCCfRc0rE_M_KMnyVYCh_4aqA-07hylQ4evV-Fsx4vRRyLGnj5moNc_YPlifdCdOc5yyPZSM7s_Gq-b86HwhpqPJ4AUNd7-edsuZq6C9Z_9BFhk4I3-v96IGbbcOtri1c720bh7P80XAmDBgbachlOY3b-18flrIqqhOvdJx4MMNAuwixmiXOZHds3WEwNpEyQl_6MabfzpWQdV0N7Ls9vQHX4mPhXb57w3ST5TNYVkUNEyI_spmtfPaWRg_BEo5uuP-XI2wphQlOZwYaYyjo6ALh9shsTFU8gJUXVEDJsMW68cLmPwEyE-5Pg9zkRGl2J2o40afUAA2S_gz8S6Frh32m95B6oF5odE0piY0UxJKdUJxKIP7F5GJvZVCV0vUAqiRe9_K0qHWJWqUyarrd3CQSsP1boyodOpRF_sqCFO1Xoif8cUZA-ARZzW3EuvL80Gz3KHHThIY_ohZiTAenRPTLeqaMPzLl22kA2Gn5EmNdxc=w1123-h779-no
60	https://lh3.googleusercontent.com/xiBawxL-gJz6hDMr2PnMRSCNSg32sg8t34SG7GCShTX87oEjjGsFKauX4visX-_wEYghAFPFQuh86jfqYd-8aPy2hIy9v6cqlBtcqpD_APIgZbtBtW9z2l1yIS0dQ0jLRJ66ZUM0RTiWvJolkmDk4oz5H-dVWSg83VfjSA0cWcJxs9ZpErqa5ykirj07FnFRWWtRPDfuX0DjPU1fdFrVRJ3ow95K2ESkCT7RpDyBDxDdHmAATPFOEmINxIIM3AHwyn1RxvkAiDx_8YXL8TZsAngkeI77vUZ54rA9Fr8BIkbiy7PuVN6gQHh9SjZkGBm9vR7XkMElQDxmtIGHqYXGlfUv7ZvgcMjDfU95GeVUSBwW629nx7EVzapM9g4xtyK3D5GSARIlamia-Oj_HORXkmj4BFmORtlqJ5O8-wAm9KtobxpXTVOqxsQkeya-OUJZ0rcwcdBI9rS-OkwOeTJ_3Kzbv4LGY4NjDOnpjH30NX8jofsV1v5iYeNYcv4JspH356uPF6krn3vx4Nx0mVMOPvwVkghWquCqu-caQng4UX6ecsv3IeycjeJ_wqZ2iDjgnyiLtCpzCvtnplaNa469aKcbMHXpLUU=w1168-h779-no
65	https://lh3.googleusercontent.com/69rzRcxCUuT1gsyX6u2wcIeDaZeTt_MzlPR1xa_GQkSIjkmbHy8mfpQvsbt9NlaJFYdEUOFxRQj81MPmA4qSyR_hhw6pKgm2I8NJEAyxhQ96K-HbruOE7cE_Bz6HIfFlw4zA2up4HW-i6BRLWR3n20B4kUpqUwXHKhKc7Uum5_WmA9shVLv8NJbLJQA-AjxtUrLM9GNuOg-E3YyQ7_psmNJkuIjEZlHnQHD87zPr8Bwe3aY0akvcsQyx_veEJl3D8VdftigLc9fbcZ1sp5y4kBb-66dx-hcF6K4r8Op_fPQAv31OUvOW8aKjKQJlAXQABqY0m18QFWZ4XU2Nu8WLZnPTZyX_O7en6WZ_HLkXkcffJggU0OY73Bua6vsla_oKA2t-6NFu04oUjcfSlb_qZBUljHYW2Qz4KCfuYcaUS9Y9I7YmB9vMHOZQGl1ivtSzCVrMk8JkWE2zDVTZJNCBbXDBDs40p1r-MlSJijPvpJFNiTP5wtSNwQoPpHAGZBMy4leS_bdyWfGWyWlk6kroWhsMTbOwfA6lSUsndXv6G7x1qCsGbOfKolxcEIaakn3OcDT_lt4ZO7ZgJCRZz9ATZ40rVptAU-A=w1168-h779-no
70	https://lh3.googleusercontent.com/l3BBg_3rZtYjw5ttr6uB4wV0pQbZ9-4bWM0AoCEdAN1JqyBjklwnj9_QxHc7UN5HdCKNuepGyrTpGLYYcAJltX9Ybk2uc08fIECZnseK_FjkntB9yZ3RoVpCIz5zEws5xUqHTvrbTHlILvSj5QO7fipIdOS3Gapmw0fTtGVB35jTz_xzgKLo5A1ssFGLu-T_ymPWDZm5CfAcBrpGz7nooePAbulPWCD-NDvhxNKvCZkcnxoSQrqnwqcmi4fYkIb8BAGyq0gotdD5Rcbu0EDkkuTu-Funw-WYpeb_qphgSSFISQLBKEDnAsfkrgufZ290Q9MtHstIgp3-ejjhJ4UovcUux4nL3NoW5PuEap-c_IzaEl419OLRjgeqZErRr-PerwvoAwmbxMYNs_v0etg1ZZRASQzcZ0KtVymqnC1lIGBOTbI6nAgLMHT2rqpB4ZSB3-CsxeDoEkAEZCNxWqrWb3WcbfgVceNf-RnB5bVNLcV0v08ezh2GlYCELhFRXi2ibsopMZE4mWWVhXV8FTlJYQXon5BwLL0kBQJmqwdowJsbSduPi_XopULwtynLNSlclVuJIpnHXF_FOQYuVna49Y3gEdZu1Xc=w1168-h779-no
77	https://lh3.googleusercontent.com/8votKJ8sQnQTkRib3o9qQaMgGZcrFDdRYCDVzCF6LABAWuWH80O3DGWVaz2ZdxkOOQRy_ZnotAoZivfYEIej0_wyFQdcpe2_ou-fVqBMjksE_UNa3BXg4ZFmGL8i5GzZlOh2ADzCSkiURHhEHuFQzeoh8YmtYXtIQ7A34bKeJv_jHfCqgmOQq6K5omrPOMNULstET0C0KfHkcMkVztTOfXoWNaYeO8gfAvAIvRQTnJuRucWjNGuR8KxCSBIshRfXkFjqgxwtU29NjJ4YGx2uGV4oNhfN_aJIxUH3-TP3fjry_4QXjcfg_jUS45GJm2TXUKQ1lmsJzsOVnve_-wW_9p41nN_s-vSfUrtkmk6pvVpDqVE6Fr4Ls_1VCic6I4LGg7aRAYx7VkAWofQh9dXjn_waG00M-8AeSNYKnPg6WkRrItEY9bSxJkwSv246O7jbc9u1RY9-r7CJ8F6vzw-tHvh-98LjFTkDsoHVnfUvIeYnEm_PtcX-0pzxjS07NuSVDF7-aBh3lMug7DVbiVt-NSxF4iZmL634-WVLVtEE_58vZAapmKlSb8zZCIa8yMvq1ZL59IIB3RAabXjM7MjtWaej3pD0DUk=w1168-h779-no
17	https://lh3.googleusercontent.com/1VY1lRIxReBmravWJt-XtiiPdDZJuEJ13dnQ1VPKlzouL5VajK9XH_2GCJ6NWn8fmChwJQm9B8r4MGVvNHTHA7PJD-GXHdKN4Tav58kZBJ9lK6tIvObIgMP5kcGQMJsFV7xhc6jhkRYO6cPlrAeHF8UR242aHJKVCv--75HdRB1-TQw1zJhOggGHhIqKKD19NGXqpG3t1n8CFzsYKpllTEYEuGaz8Hg13AEcKHlBH4nDOYF-SVl6H56JeLIXhTTKAYRvRasJCg9_KjKH-Aql2KT95ZJR26DCNDpf03fYrs3G_340DRXBFPggNGWXIdW2R4XIb3LxpZFmK3kRtmO0I7Ye33bTJT95K8Vjqszz4d-T9worGSflpPmLcoDYK-c1050_QaWfzdr0PPnEAxUR51A1bHIm9MrCpUpR_I8jk6dUa2Ng2VFQwwU1J494fFoIMDqJQq7Itj2ZCLsoXTs2byGcLAp2A2F7bXyXJDahgatVk36umKFUfnDEkYL6ROAVDGsOvFrSIS0-PFW21ejc_5hxhVFUi1pq02-znCGrv7dale0S-vo8pCa6uFGR_uCtcxQ4RprONIT-mhGjqIUdiSDk6gbnNnM=w1988-h1326-no
24	https://lh3.googleusercontent.com/0uZFnQCV8R5k9ZbhGPlVw76Kc-ilskRZIdzOq21O5Rg2v9_mFUYoYU660LwzPo7aqp4V09iQ6SVtY_K-mCj19ukOwRcJz9zdanyv-cSxVU-OsTxDPjgl8XFpInwb65Vy7PgUTOO642K5ioQIy67Nd2AhHjM-gkm_4vq13eNohSczQ1nlD-miCj7h3MvrV0l2XNQ3V8_4nJGS0BC2kav_rQGzG_qkmAfM2tD-bSEY-fGE3fuPBsjptetOC6q1hCFUprThp7CBB11IJIaOESH_z4sl0a-WOKBMK9L1w8yJ9xLpw9BbkAPRMM8TBvyaxio3Hu0sLjLtAkT6X0fz02N0ry1PM2t7YpGHlVNdwl1tBFUloK5fFxHXnKTDTsWz_cyhDpIpD-qgeULuqXLx5KZ-1tQLZTipjSE1c5mO8EQAWJ79yTAz99_Gvd5nFrLPeBFi4VSy08i6aIU5R5u19kX5kFKzj2ELPjuBQrWtotw8SuWUAroQSWGILHQDSjSnG3c_QUgmcpZ3farKL9an9Kq53Qb-E-4dII3pOwO3ZynECtL5q3Fi_K42cO6s2bUYsbw1jLGfa1kzxNchqgeYVi5lw4hn2EvadOw=w1988-h1326-no
43	https://lh3.googleusercontent.com/PbPIoCTvfuPFulzbX09zsZoXFSDOBpSf8YUATK6F0Z6e65_7wO9d0RvM_0bnD33H3NUr9qlRYVHgNyTRY9J3M6wUWl6WB0Thz4GKCGNogh9K-zwdlgPuDp51tosY3c73sEpeLfiaCFWa2MvkfHXasiyzTJsOIVAaWyM6qyKH8SWLUf_dcNa5BA47dfy8BZGSYVXIC64sx_x92suAzMLNAQYW4pzmtQMVksU0QG08b0wVO23zhZzlgku8GYXbFhrywUs8ulQwSFTIaEQdit5g8mehB6oN3gK4j2-2btwbi5cqruozAk71nbnyvVT516-8MojPowDJ_I6Mk7_sdnqw46YFvUsuhOU751SCuIiw3pV_gdOLncA0ix72xsRF8T6Je2GqU8b3-9lDSC390P5qU1x6A6SuOcq3dAzUiwoylkNrFfSRie3qTRTaNT_vpTjqCCJYYDsubnpTC1Veyh_SrvOTBl2SMxEwIvzLKzqoDTo0UplYLme4dYAT6wtL6i1tPkPobVviCXEHYVgczqcxlqgFCKuH6b5P3gE-yMzzuMpCRMlArVEZRMB7rjL2GqxTn1Azb7QyVYOZ4reGGSljR9Cj4-IsWJI=w1168-h779-no
46	https://lh3.googleusercontent.com/9rj3xa1KYTvcOrrfe1PLE8ieon7iV6yhXgcSW4qVTC_0G4v7hWIHJiwf8I5hsWLIBvbvylMRSID1FJmq3FDSwJukBPTr8N1DZzZFc7qewEMlvynqNXeh43C4I6peFmT5wASNBaDRME5HUilvdOn9r4a2nxSauNGo7N7p_qO19kkBycuokt1quAP-E4v3OWI_L_ZfKAenpzmOztu2_NYD_v20QkiOkYYoYVh1_00TFxqVD0eNVZHGPagvu94eZzKrituwfVroN3j9G0tFOdP6_7iJS3nfUgoxDzxLrPf7QEOLndh5J1g_Qw7U3D6XjrF9Cf5NLK8nDCou3sprJiLrKkrJDuI0RmYcLB8O9jBiYkKtKa5Hry0aGaoM_ouI_KeE1qmW-Hk83Si0KwrXOdfyPm8M41VzE_fbRx6ScKmqguwD7JWe2l_TR-wAaKT73JrYdT1uxn_aQSN7LjpXjVF7T67tyIHN9xPyzXK8Cvqv8BvazSyitxmLIvgN_rnmn7_rsAJ4-M-RPiUZqSNgdKKM5eh1yDy3HXsBZxtaYa4tHhPZgMD5291Aq0i1RkA5INH3tygP6KUmpmdbuI0S1WMhxw7nkttmno8=w1168-h779-no
83	https://lh3.googleusercontent.com/LICTXz4aZNdtYwxj9SeRlylv05oq9SrraZ8tolvT_0tjGAYecw2Z8OkvfqzCFiNx4vzECr_ZovuARHZx0W1DlYwgcLRYzpd93qov_eRDrj9R7tcEoSVcMaT44UJgWfpNJMYiPt5iPrStZ2udtfXYnGHUaYVzNQIMBRlZOPmV-SMHlfPyRTUo_R_UBrmAwCydHPb2Rdvn55Pw2YbvJDBYH0FfhRoA9I0YXfDHH07QSc2sPmqZthlq7Er3UDB0KrQLB7Z2Km6v7qiSaMG8pYAtergYzEUZsufJ-bd5M8HjBwXsvcLyofP2hayiJ7HL-Z84tPH6Png-ZiiXEM7z9j2HxGI2BbOHtJMmd5E-KUV4RWRNZ751DKQxREmO9P84v5leLSCTEo4uet3VS2-ytgbn8mjl3X_tS3WO1LVVHk2BHU1VWLKhYVpD7JGJvYzfmZf5JCEBO2IHSThHxbDiCEt1aCmtaInDO9UX_MrZcLLl5lxGgegutkohwvWm8TivmXI7Vw4sRJSQAVAqQxQvGMXTZJf-neG55zPu_FYWJ8Ss3HN7eirAJc_BfKr1QUWqGjDXn81ju4csd9eAMsa4-FzjzvIbQ0WVrxQ=w1168-h779-no
88	https://lh3.googleusercontent.com/mt3G74ptN6aevoF-d1ASD_9IL1qrdZ4He3CJ-rQfryOYmWr6ewN-MuDVW6KoT3NJy6buh5zG1HSOnW3I-k5IOL9f9s0hC4SBoMnrXWtDE8nOmz85Cw-2bnNTcsb-J0uj5DWZd7hs4vNAHQqGbFzE2yGjwvjDmHlfqU4OtX5S2dWO8r-Bn1dzEj33k383Ii5nWw4Vhkzc0lS1TiMgDaeQA6uDJIiagSiutg4xdVknQSNPbpt29w2i7Zrujiw4DlJ5PsmgC1To8FoeBJdSWT66xamXkZKwuDKLu3uqvwmWbKo2KagHXEc2y5_1SAVRTNwTgLL7-bZOStuU-AWIT8b8epL5PtyNNe1-YxKXy-TXb4hO-Ahbh0TEAtijJMQIGagrrPAmMU-j0lSVZIl6iCWIGN9fkhLNsg08Hw3v6GRulnzWE0i7Mb35hlwqOYwBxQIjzdPpG4qyecOPnF20i2j9vYFZJDepgZs8Y38sm5HL9vH0XhKg9EB5OnOQ7GZz9Y6PV5XHmTsAp5m4dpPlnYwFC2eFXJLaqdJRxDJBZgnshVhRQz_wq1w9VlfOuBF3867_VWTIfQvsU8E-giB06XM0jW39YPsF5O4=w1168-h779-no
90	https://lh3.googleusercontent.com/tFvL5BliuEBRkkCmk5uZM7ZnRnT6wWu9U9PmtchNjHFXtWwh_KnGBk7gaUbZDalmaF_IfQ1MHxH8uKz9TbkmNCVHzSNt6kdCaiR1sefXwNoP3wTeV8gAOhwXL9gKjVkZqnv43oQ53p-cmjeQ_Z59mArdd6EiJ1W1cDyfNRmVn0iwY2hIPTkKZvewKkUn3gy8mBRAoee3OkyJNW_NDrEwiUUc1r4nWn40-14UNPXW3EAxR3fTzlw-X67fyc-y6diqN7DTDQRDRAtJjFnvAjNXHQjvrYGUJ-kyVsr2xpt_61f8_U-AT8T-zJwxYKeYx2UQJ2oDYhRWQJAWJm2Pc7q9WUcEO9Y-5radeijNoXYUd8ZOQZ4IDiyKSO10IilbiambQc4RzO18iZSQSf9x4nZcJOjte3WMKI-nWakV0GZmC3oCKPQEt5kFtDLzaDXO8VIKKwQ9k-B8c4TQ-jNRQWnSJQIW7RSZ40GbQy12X5JgwctnTlVC9uOX9fFKQFqDZQrW5eY6OjBfUA-gHjjwk-Fz_7OB492AI1YpdeK0P8w-Lzr8IGo_roAiQckov9zHce6vhi26KwdRV-DDfPVI23mbiJ0YnHKtilk=w1168-h779-no
92	https://lh3.googleusercontent.com/9gSTdztMT-qB6FcDjx-iT2-6QdFNzEIySkCPTFRkV8a5wXPomHA-1VH59OSd9Bb8KoSDBMW3OJxP7HJyYGKkIDgdsbw34lwevNkQ-BPKQHAJlDcEY96RegeSBVtOMlZXuVqsJ8YLOjWOHZZa4xgaSe6roHHDD_uyyJf8EaE50XUUIf32N43Yx0bow6XL9ZI_qZEOWLa_FedIsPF2HNxPFyskhvWX0-ML3ycFa6hu11m0xxQb40FcX-vr6hmoLkO-bNB6eTCsuTqXsRfsThnbKMPmcabLidN1i7oMpWLKvaGCr_Zk8_orY3A7zZ8bzFqKHXPjtGV87poPYSdDnlUwc3H8aMI23Oh8MG4jeuGr-5FOGXR8L2-1MRzqBAJOdm6Tgk0gz0-KhPq6eFceIqv1V0vgbyiayH2C10iIOW3P70c8uNJeZBJz6qOvGpHuiDB7XMyoQJO3VUOjkBr5PvCSEiNPs5n9Py2O-hoSN2VH7cKIj6OGG8DucqTjLSI43-gsXdnk9uNB4Q90XSrjUp22GL07xW_xnAAf5eanNPBziKuHu15A_N7ToYOgwFyp4TJICdvSZSZ3gFw0QcjT3rRBAJc6VMxKmfk=w1168-h779-no
93	https://lh3.googleusercontent.com/NyXpWxarXaf6HHZLJhF5ZgqNLr7j4zlVRFa9p3p4rBbBT5XNDV_x7URyA5Q2BSNEu_UWv55ysrcFdcfHeAF_M5j6CpUT8QYPsPySRkdaQakpE25zBXKJ87pi6zIHdFn3pFXXQrhZ0YfUVojwTHV0Z02uIQGZ0yviP-sNzn6s5Ro_3YbX8z4khFGmGwrwQhvQs12-ogbNI2wH96hyQB-amXsIafzE0kNgNUW-IiVDy5NysYnHC9tAFn0U6C2egYU6YGzI9HOOeTbASKVxTkxEndUuaTpRwZtYzB_qp7ZttuQuX8J0mZgB8lyPnaBQaaV7fKKZzH1Jq21Y36wcw2_NKV4Yv9KbMFca6joiJufHyyLoHmNUwyLn1qA5_f-x3GMrpITn4Vfyc57Ubug7ZDUNoH_RveH1lvUPGdggMwDga2OgN3wLoYgXpJyO1t0BGNSCzCB1ZM6Vk0e-TJnwA3NVRlnIwMveLjhihMFMz4VWgq2WS-rkBnfNJX4QZrNYHl6YE2y4q9FctzLggRVOgZ0usvzh6dP5SpAgtHA3Xa8rn_ddOKLdWExcTMmzERSvI9f1kYsVEwb9ky6N53-o0St95iTdcQULAXQ=w1168-h779-no
18	https://lh3.googleusercontent.com/UKk9uzBLes2hT0ub6SoZXNVrXrISTWrxM9YJc_juMl-DMb4KLq9oBNji8qQW25qZ-QiFBlgOpjRt19AkNqAV_wpv9DQImOmzFhPikvfhzIzJiKY-ECr4xfpM9vNEeHnaYUEI5y2fSAlMOKxzqVmXMyivlurMxcEtjMiUzGPPgd-WSjVN7H_DszuQTCxs7D-gP2pQIrCw_dkGik1Tg0hYHTkczXM01uXnpGOYv0tT3PwbzMC8T5OOZN5uJp1mqUGU1d6hL0n-gVEpyZQ6iZlV7zkC4T9WdFitfJYeC0lRYzIVmZkzWEanj4pePn150BmvBwwCmK3NNtZ6lb1Nx05urZ9qUnUuaDCl_mv6LmUN0kDOmWEpwa7w76LII7QVFaunukscDCBb2nSl6EgTxlVNFpxnVcPhU-fyaunouov3pvI_jMpc0EBDKxnLDJOpslkU675eUgwWNd87Ki_rCC_PKrVXFtUmAiRTEJG4PM3oyv1WqSjoV1wJqCMNBYyiNt37p7YnNrT0THAJjWY9JsrMBlNr_VXx2ALYR6KN-2glBXFV30euSGjlNJk82SzjTs0ZKCSwAnKV4EXQ1SXwwEQg0eCgEI7vMKk=w1988-h1326-no
25	https://lh3.googleusercontent.com/d3pDMz9N0VcYXypvkIeCosfWwK9_6MSK3KWHgISIwXA2Aw2kE5SW2fK3a4BpNeKc_b_7r6bBb8O3JRXu8vjwj5keL3IVGWIB0Q4nL4vPR0rIB8JRIHATmVweSOz5vVfT_tsLDfGA98ZdBycD6FssyDO1kqq8_HOZJ422Eym4V6nlpxQQ85DjnS7oCsAGBspr11iexP6UFOq1IGRExiIa1jza-sikmCcdfkMnx2o-NJ2TZaAIq8pn1d2AMSdG6kxo6eIziobWjarl_MwBYtiM_JBrvWjgQky5XPaQwIhpYOmdLscgiIYg-Gc0l87Yehl8_LHzHqmNZVvp60NyJS7Aw4Vg9N6stt2XxbSRaDTfDp6nRi5k9Kn1Sfi0O_y3MJlOQW7jRsbPyuHNFkAQM6TS0tJoVrqI34jG90k2e70TqFEURI9l4y3_djM6GfGnLlyDfZ_UhUJIYoS-oYf3hcGWsayOty3lfqfkDHMxchU4y4qMguIvuTNt6O9a1oIdogJoTDBpGSawlKCivJHwkqPuejdN2XZSPlTLWEuTdxiQ8RrSqeYTL_4Y_kZbSpDJRBuG9LtPjFjsqupHeXcLOwO193INIa3KNXY=w1988-h1326-no
31	https://lh3.googleusercontent.com/V3TALNqJjTA1J2jj7Xf8piPnuZtNyz82Wg86m5YQme3aAZ65aqhWUw8yXzvid8-HQLEDG49LdN8pCNBuU8dUO6qYWXZPf4i6_QwYS6ktNTwgXHk38VVgUYcXMyCYGJUHDYscmc5oJZcD9lw0lC5Cre_nO9gsmKIYvdesfHzji-h3bsw7pa2sv5oTO08nw27OFW2P6RBqg2BnJ-9RaaWOSfgGUWG2_QlBPXGRvHgbVuAT_m1geSmirO9qy4PyUcbs8yeSlqmln_IKDIpOQAecZ67QY_RnDA2wD6xR5P-Cz388OnljveOKsE-fPObCGHZLi2TBQw9ikeHn8RKS_pkFV9ns3rAvyVY-94tEd_SmTpdAzM3MVYo2u42BSg1ASzeGSeXVjh60DU3yZFiXNYy9PLH9W98MnjM9vXvJHn4BpG2SdPLJi92rW2DzCcW-zNjJiyPYVzPW4kNSlxuIpJnSzxwliYQW29ElLO1E8gX_agyJo6w5JmldEWlzYp-TSEXzlDbeqD1pvGzQ0n2LZmxVQ_F0FnnBtJrndqT3-RpvwK7xD-Xiay_UtbeRDo-kphOIApItyQ713H0dWLIO7QFRmlWNyy7PriA=w1988-h1326-no
62	https://lh3.googleusercontent.com/zxNc40iTRWeqVnM9cr9D6vCJbMik5xF8MejwXBqZjuMtOrg2NaJKBK3ceNaw1cSD7Dvxw5oCYX5_FgkHQ2uNHE6yQWbTc6hOB0J98trdYQmqmAUq_SxrlK7eWzJTgK6ak_Hu0OgSYM6YluWSg2aOCg9NDw_xdqdzckR36wUd0CT1i6LWaxNKGQzb_07ow8SlGXrA50iKrO06lK3rG2AFKdJEVi3YA8gjpiGo794-lEagpi5rhYUIFjrKdpKKz5qkIzPpVHjnHISV6snC22nk0YDyw9bgDpvcvdDBmkxH9PMjCd3iiILhDHFTyN1HQ3VlemCEl5uvvEA1v6PqSuIlRn_0n9PEdxImnFdeHT10KcRMI12WJ9IXjFG2I3Yd4ai2P6UviYFyHzklv5ww4JMxQwhWC4A-hu46sxiSa0WiQr2xvBbNxnEebArckkZIUqQt-02-6Sd_V_t89ea7OcTSvlswgMhu05aA3FdSjZECTzE0osbTbIBs0aajWRoGtFu9uZAhIwZXllVn65QZ4MLpaPGJvFPJmNamfsu1q-IG7CFJRPUkx-iL_dF7QfLOnSzj6HdRVIkBg3HR-q-WGpvDL-9jr7U68t0=w1168-h779-no
74	https://lh3.googleusercontent.com/7cIw21T8AkpO80-Bta00Mgb-8hXEHFpAayIGLOA6fiAcNjfrv_Rft1sTEyjeWRBTVvOr5HN6shUPQ3UdMRnwNF7ic0edrZJmDEn9O681SIZSWtnJQSIn0_4LF5zfpsmOyYRUUM3tj4uehjRk4UreioyxV2ayQjXd5Ie9Kbg6Gc6-5dezK_VQ2cyFt5ujmphb6zi6wdE4avuDDkuOyf6j1f2GwkennisjYID_gnWYyobKpKmrl7N2zuRuXjlYFUCBMRwqMyxmFmEpLEzfhZ1tPo5RAZC7bVAvJGAab-avjDdpErAWBmliNhAaGxsUWVVyPg76-hETiIni8ymhMgmfrLWOCgQEkoxS9dFDQESV9bB0eQdipqka7sOzRG947dmuEtgGP_DdYgxuY3I2y48utC2n8lKo3EVN2FrIR9xVnt0qEdI3_tR1EY6D_IpMMZ3ygDS-rC7dUeCMEdlXirJ2B5TulYsfYwf5Q1B8fqhc1XTjFQfe5hwhUEHk-RuZGQPrt4dNvilLkkWNVegUAd4cA4-qSZZprytMjVfqXbijeuANfJZgj24otZZKyjVN9pp5I2lOG2ySrY4yrAPMRcJFLHo23RQ3Lps=w1168-h779-no
85	https://lh3.googleusercontent.com/bOrMU1awA5bfM7hCVgJeHAPK_UPClCOgzPUB7MVc75ao7col-kuFka21yMMSZZ-I7asYSFwJuQ-7xh7oEj4u_gBh_oo-u_cBF2LwLa0mUJzURdHuvVpOkwghv6aGDTMke3TkOhEzYj9nJjJe6gPht0wS2oDmw6UIBRmA10rmK14hGOQN3hlbLFCE7ZIO9o3jo6iaDp5V51Ziq4NYR2TZLN5WlVfiNYd3NZrry_RxcP_6v_WFvANYEB6Vmk76rTC1Gc1Pe_ufGFs32500r9VCsEMheQRkBOwEMP-Ehzmtm81GLboAiZj7bweISG5MsVxqqPxM7uGGmWn3-1f7jP5yxdunJEeLB1luEoJ83Dop1sesGnhhCnnaCQf8o45zmhHGqawyhNdzW5z7h_jclq2fi2-fTzVk3x3vT20HDpgB20Q3xNeRmXumaGr1OEe8OdJ1BP4vXFkcs2ZGMd2YnS6H1QdOdj4ytXZdgVtbChMz_L4YV055wuuP2RxVO1JhLzk9KxrzxnkYXrPr4URDj6gv-OgPnM-5ESRlRGX7QFoB5choy3STKCC-xVcIMf2JMpQ1o-z-BFEixpZmBd-GmTxcmzG5AvA-uOg=w1168-h779-no
91	https://lh3.googleusercontent.com/lthAC4MOtYFCDmsvnUJPdwOZgUdTaQWQQ0tGrkqksTuR0Ae7qO2d62Yi0PxUE673kk64f_2KzJ4x5uc3HJ4S1wpbF-2HuYDe8qL8FI35YCOeHWShUBXxDX8FMSG-a8HolXU8yjCTfbjjOwFKXkCE8SYhtIJlN6psXJksGvV8V3QATEAhCwD96e4fuNDVWGH7NS4T15aTpYiBtV49tkTiZnb8tLkJTBUFyZPmR7rwlQkgVKtHmMlrkY3psU9dPwF2-5pIsfuSjl4FOEycaUki5IIoqykmZo--6Efm5y7o5ovzdWU0bcUUFNRsTcuklyzOGhtJiPMJeT6croWwDdvtcPWebvEER24pAR3556gSsI7J3r0aexHmle0CeA5sdUoIC8on7YQAyePVkLMuwB5GqRVSVGmm5Um0ppC2fTs6A7LRQVchprwOME0bxKU48AfwYnxAKrEouxsizYOxD2AM4TbyS5jHxlkYj8IHUIz7GuovYPqU6dHg_dUVGMd7SEVcQHo8VmOcxxTfbVJga2Eedh98zoo14mijXQC7zfAj7acf9YsD2BCNOMaVkbCy8l-7xRD86GQO2quCRkQBTc5uh0S88MxV6iw=w1168-h779-no
94	https://lh3.googleusercontent.com/MpBitv-cJPZMubnIHpeVDHD2-quwFicwlXjdAF401nkWBxBtP1s2em8IZ2Icr_IxlKeYRFJIEBq7wCNTi4ttYgEUseHVs5ginLoT_1AuNtWzcu2sqhn-JrEIqLy2gQGMfgFz0iphhrkeBofUSmQq-RbPFcnvM0DvEHj-uxKuCcees5-Ys5Cgf03oJTW9HARWWcvqB6iF74lnBz-68pAGJsk5J1R_p0kLYV7UlSTb_Pfk5UeKcuo-U2gK10cgNfR16D1lPGGbwhYyKyAXzXJEg_TIZS4aFL3D4WKx40McZN-aFXav8Lwtscncl4cvbaZrgQlwmPRwo5E7_8une-OTJ3NV8c6EQZeN13p2G6-oLWhtbXGIrVXQQ04bXUB-8aBgWmTRV1jJN9h2tzESI7SWnKNE4KFPdE_AyMoGZM3tZHdYEt3TKQ0ecRWlp3RaRnGJLm81FYc8HyxUTmruJ8sSJP99lDFgnM8vzH1KN75cdF_okCh7HEjm4cxdKlF6Eno1T2c99i_jJXjCazXwXYcTpXmzYnQzmXK_wDAn5vCqr6pc_BFw4P88ZFEdhxISwpYT1T4hQv5hsitkSyjkvr2iClmw3s-mENA=w1168-h779-no
22	https://lh3.googleusercontent.com/-TsVJVnn6YiVHzsuI32g_t6OuQo0Zhrrcp_mjq9ktfinziekoR-1P8UbKdCd2Be-FjgBlfY7Qs__mqjDf2Vm6xgpTJxLGbPLIfFjnCbgwKiad71iPd7qeLpuzVQwh1JX9OXs_xfKdNdDHv-PUc4qsggYUJtJLg5tHEtKeu468HHckk2B9gouV8IOh1P_F3qpbo5mDy0Yv9oFpC19Z56DZ3cga0EOO2O5M7gfHAMa8WST3bjcQnAPppHSiXmR0D_WAMvSm8_jFLT0oJUdn_8ZagawXMhw9Rom5ApoK2l3pMsvcMeVW9zaYbGLqBDALyWfVYUCBZZhP_QHKuOkKfWkhEevqLs-oI5ELXpaTs0gdoQFdrkYTBTeJjDOihl_HoIKzKdbMZ9Y7694xsN2nu-ALmzN2DrvY27WOTBglpokkF1naShVY0R7q0EQHeviQRmCtt147BgaGhT5SLArGWPEhT33IGCvhI-MAofFs7e7I-f8eExXS2RelDCHuvb_F4k8EqbpaVwICCyssQ9CtCL0-T-3Lj4VYmSTb8QBwFZ1FHmSweIYGMfYsfBSPMloO33rV2jYpjd2RjzkSuBvYITXlIx7BBWyaAw=w1988-h1326-no
33	https://lh3.googleusercontent.com/1s2SAuXM94vRyFk5IBGo2WyyptcQD-RUIwbw2AmfSk4qFVRrj9TR0EwCEJYnOV7sDl8h3BCrPePngtXcwfpGZQPJvOYa-JTqikNlw8uo4lgkdOkuaODa_hTydTa_KmiXTChvFBDUmfWiPgZvd_180g_tQUhYbfGFlfhLJ9GZm4OQGlg_BblfTTpW7Nj5irLjMPgrYQV6QuoDLsLQzYD_RlkvqLLhbW2QVSbmQCInSbCUhiikU5uI962Je42kgUZCMxWgSF20wfVD2bhcy93TjrIG3ttZUFHkZSUs4DBNaz2HSHPPbBXP8k6Zij-3gy-_LTWxtH9mayfdOuLtwlPyXcvYhQdjh5T160ETQvaZUWicc1JTHHR0ff58Q6qu8lULU5isTQQX1qXblsbtze9xHrObx6pd3W7ePLOo7nYnXlplpsDodpSX0AEG1w4YbqBmXRfey7d5wEtfoz7Vl2NjD0FwTzRGkZOvEMjydOWevUoLhN6ejX3TZc2NJAB7C-tehrah4G-3F9bdjOyTW4_LKK1j9Oo5fyyYl_58ILve-l8l54hoBA2NhobL9xx0rq4OWDAEcmsA6YZPsWDX4mxDSFIEU1g1e1o=w1988-h1326-no
37	https://lh3.googleusercontent.com/PnZsI1C-LUO6xBUxEaq3xpN5B1N98iNjFtfk0FoPVwgI0K2bdufNa09eb14eVjz5sJvMMRwzV_PNYAafHISHw9DP-36i5mOMb-ut82eagkj8CVQ8c4GEmN91lRgwSJVmFEvPs2kwnIj94yy5c0mxkBHHuiHHVGDx0t2jgaoLktqgZv61wZeYPjrFQ8rjoBYLWj18U-z9HX7gszUBU0BTjzxL0Xj4T0cd26CJ8G-rBfh3Ojq3Fi5qUk4czoeO4AXrpkC_ao5UyrEu8pCz2J5BIyqMcYs89N3kIytGJTeQMQPJD037UN3zWQrs-o4UJspi0v-vDirWzIEhwc_zoXUWmjyW58im_T90cWQJjDUBtRSDEuJw0fnxzbk2D9ZvzC4pLjtZ5Fez8suRm2iD0Tc12LaWDHqvVWzWQlw9dmzsndINojssTxHZc6WoGfC9qmEIN2mQP2tBU7T36x6ZdwN-HXVrdiYbhMR_8LXbdXvL5eSYxwX_dvMWxpW3JOPUmqyGao5ltZW7RXmm4d6l6yQxQbdYpewAlkb0_Nas5CW7kG_tEkIcGC6ovXm4AN4x5waBA7GsDIN03wkRhPC_fCd0FSHvXPhibWs=w1988-h1326-no
41	https://lh3.googleusercontent.com/jIQbGLmD0DY1zt3dlbmTso5ijaLsUAOrTyGngimTPa19W_PR8Lmuy5IFp6c00KMWM7b2a-XYiWz1m7zZstSBO5t7oyRQF1RnO2RBpChMgaw3fvi_u7tLkrl0b8laGVGYLZQHfPmBm5CxifgnicbS3Vl4d2yaZmABiVuG57Yl7RaBPketklkxhXC5Xyeyfc6ADhYD_FokRb1_KaG-9fKxaJNpUknaifAw78mUMoWM9Lk0fEwnm2u3GfzosuJAT3VWHopIb1xP41u09RsY6u-XwxxajnY_Q46m6up1MBhHdZds_DGXGdhxb2qaE6Ah9jBd9FilmiJ0W3vi9w5Jt4CHqCP6b8Kl-x5ka2SuaceF6GZUCB1p7C0VU3D_UtwCltWypKMjDEcS_2X2qNjsbv7czzsSF3Co4DuxNmV9yf_Ba-7dhRONpRW7VnVYyHkNCXHxAn1Fp25oaR4MNVYoRt9wNMqX6zuu-_hIERNqAlQRjX60creV2VEAVlpj5ThFV8QgdfX_yd2z02EXo96FidV0kOfUaoHY2QNdFk0sn6lpa9C-z8Yu4Tf538fXpgjzziF3QNcJXrB87FbKXAeXzBL3ySaeT0MSAys=w1988-h1326-no
48	https://lh3.googleusercontent.com/dxaJ4oEJYF-z6fEvOPyTuGmMFR_tDwBKqkIsw-DjLJH4BVNVZ353dKeZzPEoazaPx37H3RwoW3OYPf-LpYNdA9Wm0RyexgS-AhVdRG4KXcN5Z60I5Dk49v-mjobHk9O8AgCuX9dWrvqEHqRChVebwCkD-E6MeXL4iCGQDQC9LMDyM6DYYj1uW4woAlWhpK67ZGW5J1inCerP9DiEJri4Kq7GrpfQyQV2NP_dSeU2HybdCsx9JUoxispUYmijwbcS9ETPwKTwefavm-YBTUe8vpi_neJoUjo8PHsEWMzbnhXwqg7u0hZT8JhYJCeWcXVwKwFZiu--RXAhfqcDyDp9MjypuqCOegQ7g3ubwemYOB3bxqLKloe9lVl6U5lOLSHkds7Y8FBUsYeq9xZpmgmunOSIeeeWsSx5y8_JFKJQ8mke27p0LStoMRcaJUh_5WgD-SpSo0m5nRKz3uAfC1CrVYDnjhNn-TgwT4u268SmYYg6QmVOjxInFf-DeMImhDH7foPTnQGFPF_W9BOwSxpl-qNLe1HCC7rdDEuRRMPVGju4FziE0pCjj5ygNCDOe_fvNju2cbGYxdw19p34EF-mpQJp2deJTnE=w1988-h1326-no
61	https://lh3.googleusercontent.com/SgHxNAc7tgD61r3rwKjxog8jwBuJ8m5qNnV7Stk7b8Q2EOeiVaZM7lX_mQqax5a2B2I4BMvF7O9eB9xfX1yNUPN4dtdvXT__1oCKtww42ZMNYN0luCu-ykXfqF_Oxbw-1LXHs8jygOaT9YC8rruiEGa69d1WOwKrczAaaBrv2kfCu3EOKWRMorwtBc1BGimu4V3OdlQIP9po9T3pDYsORppFvaBLgp3D9b5a_GzRiD2wC9wQDpwCfFGGKLnla5jR4MlZgw4uygvjVNb4W0B4NL1_gN1FiDzKxFAIbTt4ltTve1EeHHs_7RTEYXQ7uk8rOko0FPDBUvQddmYIBThtx462ZLIemzM4jeokvbRg0QfpO2oZttT9iIzG2NP1dwU7I6O7eKmmvdDPzA_HvKhlmoM3luuVOqXdW00ruli61nm9oi8cjNRKJKYhLLTrwOrvfxdQKSHA9u-h4IuJhiooDeJFc5eNP3faUSLYhKQLLy_G7a6684PVhim41M5sg9q8wes17LLug__RJ2GEGMT7QDvjrZoubP6X07gjUFoPLbIMQd2yxH2bbrkX4ebwRzpRX-ikPD4y7NimKtLKhNaqjFtXVsvfVRw=w1168-h779-no
66	https://lh3.googleusercontent.com/AObOw0h2CCuiYBZYz0V1Q1Jbo_3z_KV6pbvMElLKS8GyYqCR5IBMOZGZADFlBRpsBZTlwEm4SOkiQKwVyPXScSzW0xer4kMku_heh90O9WAGRDL8BZ3MX7ojMzJHUqGikw3En3QN6VusnSUmx6NYoGrtTeHEP66gXcj-Qm3pHxfnJ9pOeQgybbst0XZP11_rRQFXOsUa7_kdE9iBsZsemNfixuekAUuU-dKLK6cD0p-oyjK2fy1VyfVjb2XpIndLLA-pj8GiD7xy6fzdiiPquA6QkGny2CHYGdxO8FFL5oYj00F8fHL0AvpQFnL4Q7VlSzYq1ftrLO6K5vq6K8xtGuRmJFmaZumFz7Nnyxmjt7mrFP3TnK3eMMMan3auarYvqPTblCsKWQGWZixBYTbqujmXGt3h17TLzmPcmdlycYhNnJuH0j-SMuxmcCQesMqtFtZEgO2fTrEass9QaVypVAqsaMpIWdQUKa1XKvYsY-_P_tr8sg8B9DgL15ufPCoryBSnf5f2c57zZANahRKzePBok9nxiklN5UdL_Dqig8H0K-83gmQq_2n58cOUm4xSWSpTyhSgje8EIoz53h-OboY0U23lwiQ=w1168-h779-no
71	https://lh3.googleusercontent.com/jv7yGisZ5gzOCHnN2WUFst93StnkrSQTyEGj2tHtTFKJbAN9mIql8VQrqyVqz-XBHsjCVw2g7vOvHDU01MJPXdZYjS-RpG6zMQ-6U8Gj4sf6u7qx-5ipK7dogK1ITjVTlFC8zVdMOFXTgnKbpZzl3YZWpkhRgKti_l2ZbNi4M17K1w5_JFUgYIyhQIctg-t9_gBAfpe6OAu4mLnz2SUUmtnpZNUfaQB5AMyM_9GtYJ4Zc7i_sOCVTMD3EATPx23sZGyIvet8xHhRVSDYm6wcm5uGoY8_AaQDkJonfsPvPN1Wj87U4-JWe9l327_17LEVJ0JsCyU0pKgD37GrIAc0c2VnoBwG01a2Y_yJLpbRkN1CzKCbT4YU9iZQvdkH82I48eYE7IXeZ4DIK1F8GEe3yrAI86dx8LIXLzPsnFnyLpw5LjncQ-4HshLHPu7C1zyPN_H_GDQYj9TXGuFW42NPaO1__q_G9AwhLsl8Pw-eu9WS4UbdPrsTz-29O6QIrzzlb40XoiRK8gP6J8KN1G3Ca25IRZBlO_rv2ilnG-xjO4uLCQvsYc8aYslHY6Yqzr789nONJffgHeXub24D71EkLjJV4rDpRJk=w1168-h779-no
78	https://lh3.googleusercontent.com/gYDtVJjiQMph-SZEQKDVEagV7HI5z_N4pHaWqORukHpxIhTo07lhyztfVcdgoYLZmoVQNocKlRqfcOBwA7ymJrzK5OvPbqQHgmFzpGgowY-gP_Nt-cRJArqGfNkz_p067X9ZuYSEldXNFnaa2kT1fFhbsNwwai9NLlBBAp7wfUgg5K0AvvNlLnuIWht1dQnQ0R8VmQruLj7ltPW3UwiheoOsDLNuAbZyGyEVwrKtt4w_YjBG5s0vunzeR5ScspBi_triV7fnnoydvuJ-k-lZQIgeWcZqRMwAI5zqv63All_RRQsBLOA4Ak9LZ3v42mI3Z04_BNbhzZI8knqlEfnIG-EXa_OSm18i-oO2Ly64yWqX7S9RMVFf1jUoh_LtaltSNTgxoUeXXWpKzQ0UzF8fBpSmkg9hq8bSklZ6iRBh0U3l5-4u_2KBS_VD48JI1phFLtdvMU4iwEOaM1ys3VfiMqZMH8eawyMuALaCIaR8-v4Ivz8p9IFGTPd_nOAifCTAi-SJE3JsTk2NxHzlmUqRqad6z1kMtUNxV3z7NBaWDPtbbdpoIH0Qf9HpOUABRyRggSapH7-Ifm0fp4imfreo35fBW8hu6s4=w1168-h779-no
34	https://lh3.googleusercontent.com/Jy1hhMGm8ELdl-7MuyFulgjBp6VwTAlEUkW55GlrIl4KmFBpUmC5t9lmnG9uGTesCBlRM_2OScbCIqgUfYJy3Nn_-TNrpvMpjpIS_Lcf_pyOzXRHW2UViNkSVhO9FEo_sRQEu7juS8K4-O9gGY6yKzyQaTHEvLACqm_kvWbhfReRcsk584H2JAdEqOZ0QuFqqTIozLBltUuUWXwMSMj8uibdRRU-YXKBwNY6e9gG92RpuPTUUQRkC5LLHjrcfmeoejVf7P_G-qZfKkezA5NoJWrp8LeNxgqOwv2oXJoIixB8CJFZqkeu6st84i7Cc2MpIfZ5Y6zETu_VaVBKzhyW18a9Ikd3SqsCCea4o4zea9cxzKzKsqc7dykXXHRB5bFDd-bxoScVwiZ82h6QJUQuG0FWryqHNFiwky_Q9FsKHPIYLjA6cxrZSsbvUiNkTCMP1ot9lTE52umnA1Xo7luvf1IvNFw2q0PaEcc4B0Gt-vQcLVL-DRdwPa8KvPt9GU5i7IAK84FuwP3j5m8bl8CpHlHQkkWquaS6lzRW03vYkW5oHOH7_QuiBbMb3WIEhgxsxw-scR2gvgpL2nA-sdU0PEB8yIg789U=w1168-h779-no
38	https://lh3.googleusercontent.com/z-eM5Lz32J4YGI_aRerOBCWwvbM-8G7BjfCEB_UWS_cBMH9z-vGracRNZgTkJ_b6tiA9FBjeVaXskD-D3VyOJCVzOjiXCUwINUq6lA_MvsSAPgvgpD5hFCVzNMN1Fjq5JoEuAx1xSspxozxJ4k8XcPySaN4XJc1yv1WtqJ4HYDHTn2abR27HwBwwKh02GgYAwtVNnmC_yPYI-YeT9uu87ny8Vm-m6MckXAwG4HX-bb9Ilfe-t-Pv1tnnj1lFHNT2rbkKRAr55bTXz4udKs2-M3XoVdxZegtKl5bV38qNC_uJElOMfLtVXTqM8sywY6Pd8aMaND6E2GmbKkaD6qaBZDePge6lOuThgt5cR8hCj6PxUfmRcbrFdgJd4t0XTm_DQd3ceOd3MxnufvhYHLYk2lr4xy-cHe5JlbmxJ5i8yVkbtR9z4itwQls-cBK4AKVtxI-6dE9tU1bwuMEdr7LwoRDh3tIxS-SunLa9qQqsOW9ybklw-82jAR0SB9-F8xHhJeZd_Ix05iElw_Ik6TI8qL7oHjhEimkVChDHjcrRsr4jWoFHDRG1xdghoBTHwHnRqgZtb1xOIi4ilkkpScsr6u3QrLN8cX4=w1168-h779-no
39	https://lh3.googleusercontent.com/t180AtZqOVs4eS5U409PFsVviigex6BO2-zJXCEI8mobzya7iWlQem8LKqrC0nmg5xjiOMM11cB9B99B83X251L-pmj9xlL6FXipmKP2PZHINlwy3822SoaEp97bXpSSbyRBYhk2CQxaWm7jkkqvSxitaGZbyWCWH0n2VWUUNJLAg2wyGJblsBCKSCdqGmrXzAaG-ucOVxayv1NwTs_t4zTKIBQeXA3JpmLxlaBQffPreFEN_IWjsf25Dg0YB37qx4dRjGrbNfnottIoj9H6hbZC2bX1TSNY0hhQloloSYSoa4wT8yjS3uGHiKieiqnNNvjJEwgdspJz_gz5QmgcAw6vPKDaJeeDBCL7Lz_Ek5M3jNJCzNgctmpyA5QvaJna85es376GIvXLsm_UJpjQ3UTLTSRvCwRui4zOPZ0QMaGtWaS38ISSJIDHTa8WRmfQoz4g0LU6_jls34tdiHCer1g9lqlhyTGO7wLjXJmozgANJptvOOitaxPAsGfEPBNg7YeDspxkVrwFfEkn5dX84vPf2rnSQ2yc9YjUOzAcbLqwhX6SM7JphRvcbKElAIEwF1q244sf1lYWNIjiXR8rhoC6ysXN07U=w1168-h779-no
42	https://lh3.googleusercontent.com/V-T-rEadZyn2OHdBYI-x_Dra8lP6nSy2J00SKfEXuVbt8WjgCV9ws8vh14JSui7ZRwjAg8QTpQs-aQBKkmRFId3rNk54AINIpE-LJuznyKn4Vc0ccOOZbU4n2ku7MzipwrR_uqtx5l-NlJqczg_VJqkdydPfMxpNgCxXeAeTJMy87nJzz_vzAihSOalyYePSrl1851vafBG-qVUJc1lukBhOtsE0M1OuwmFIBJ6OOWZsx004aJsFkhkdOdaiA2z8LG37bnG0eA6JLOdy4MkjPFLPe-ozpnCSrsyYO_-O-pltSySX2ksj18XdGGBog2lyTumObpywFJtAGU8n12yqAMQHE1WE3aszztadnHAMOCETByNpuTG-ZovhxvXHBhGnhv0mao8QpsjzfUtMmZ7Ai3s9H_sPtOwZaCIykbk-lFFfpDmuPbcHFDcwykdbLanSih80lzE7E4vk2Olu42-IdVQ-rqezJRRqvIwLxDmVkGbv5dioKF9FppBP-5Br8XJwL0_NSCEV8XYvmVxNpqnBM8Dw9g0027mZ5RaRNFpZbipw03Y5wuAiDlBojdLrptXNpqQS-J9801tLTEc6nRfifBDqaTzlCrg=w1168-h779-no
45	https://lh3.googleusercontent.com/R_EB6z6T0sD65UfcWcyN4uvKxj5kS6DaOqdLeOKk45YgCizMEypbzH7wxVFV9w9Go-b9QZOf7uVQUjhyuit6bdwewz5jMYmBe2B0QO76w97zYpAa3A8R74J8oHkHxU9luZDAEMmgqZs1qfq6cVwUK-yBId6BdYN9DtiA3k9Y7gboWC-Ft2FQoZYhrdXU04rX8T3tDI4DH95r6G7FYkH2TpyS6AjYKsmt7J9-oKpV8IQKxkpI-CmdosS2QH-zPyQA7I_K_83d2BBfC3VOhHxzxVYF005Z2fPmaK56NYsE-8pEAD3aj6C3Jbggf3Tj-kOlyhFpRc2IM3QxHuPR4V8wBHFSlQKGrcGIQiRjDyooxk18CR1pDnu4jMn-HFY7U89ZXI_WAG7P9wNM4Tai0671l9O7qT8l3VXwUOdYIGhxTAB8ZCZHPcficeChqlSUI0wIh4_PtwF7r2vlpVpbBlroxDX6ecdaNSU-_7CcoSeNkAyGCoAM9gpAW1bdluk8oHgETuULbexdq6tIeP5fCA996-bGCVkcMt49TG4KWOb8KIyIw6OoNFxbVbTqGkXJhLdctEfpNFyWtjs_ahKhtdRS4nw8di5RZNU=w1168-h779-no
76	https://lh3.googleusercontent.com/t1ZP75LHSDBMZbxSVOqgXgGv2dYuiV48bE_snr0nGqJl_qUjagybWjsmvKmgWbmP1Eu5M-yLR0bj54K1D6V8PGgzcb_8gN6JhBGx3GDD090KkFsUmTZ62Z568d1XU3BuNrqLTuhERVCHPuBgsnl9Fgerzf_zCeJMSjyL5bwkK3B0ioppfZ5fm3vOTv1yz9x3tmResIk6QjOGnomuxfMBzWh1BeOf1PSpzd848v-CVWOQ0dd8aL-NnsQ0T-KtyRUReBoFu21u9km50atco8b4frRLXSVVuxInxQVaqwdQxFZLdRkctR8OECjR39l528daHWrBxVfFcMTAkfODRcjwZjbzGjRN10X4n0aQQcQz7MD34qj4rWax9baOlFqEfVuSWoxFd1EO8Gicrp-elYpPMlSrJQcUxGYZt4IVkDa1jl1vHyXBa7SGv_CQ95M-hAm6H6nYZOxkY0C9mbWadbA7Y46cueYuiNrINkNNgwnMFYkbvjV2-GDpHaCfRVquDY9h-mgfAnKzviGE55JTqD8Gi1pk5zGnnL5WOVCPV9Pq2zdpjOzPpFBmkuY2D06ItcS54ZH9MKbMM1llp64di3CSKCnzKzZigcw=w1168-h779-no
82	https://lh3.googleusercontent.com/iiqgXKy4aXn7OazbXtRn2UIeoM6eakNxrKYv7br4YvfKWjCucRrr-jkxdpwoK171tcHbr2YxkpAKLshdfFzRrR5bg8HgdSIez3QRxlr4FBVWEUk7VfIbQKd-7vuGR-noO7dpQVZZeSCp8KnJ--FMAXOGA03Rw6ZiHQ1QtyHLBrN9VdhgPfqD1BXYCLIYxeS5r6tFL4cDSUmPGzTSGNBGtjiVTPwuLieU2YGzAdN9ug75xMnfpI0Wp8AGUcICrHPo0s6YGc9WT1yRfUnue2UJSIl5TfJuxYqKX5llGWD9yI7T5XYj4hwzKWUjE-sANrwORmWT4F0WtBaQ4otbM8j4HlNKV3OyXhgNCEfovSWcOqLcSCt555RpD8HIrByb0eO4F63tITLEQ6D1WJ3kIMWvIepeZle6tAdO4GUBRZQkvXxIuykUQNb3TIT4TdgcUsE9yHgDH3vkMjMAfn0Vdvvb5scPLHKWHCpYaPIQCObAPUcDDMkXhe2Ct3IrgK54r7oSBZECO_PeDrNQfv6FG5e32UtiPVea52vdtgHy4iS0ceWxuxC3vBYOQGqO2bXsItRbuY717FHPe0kDlrujZytoslxrsqqaE7M=w1170-h779-no
87	https://lh3.googleusercontent.com/5vGoSTxEIUbb0_1JgumQ5OXdBI9m-QVbt_IpD-9o5dqFRoCn8kBz5YRoPMa5VO3SN564OpUkE-V1pidMcEaEr_bfb-FyWbTXFO9kKwss7O3oM1L_g8tEF2bZOHvo9U0xaey5q0HBz39Cfvh56WOw-DU3dImo1mvMxCQ-j_eeA5T4G4NjN9j0K3iN8sRj8cTu6rrMIRllEUkhuK22Xu-ly8Mk3F-c9mb3-EwI5TmhQK6wnJAaNRkqFlAL6rJQ22wAONsBkeojIqZii768DYkHZvlIB9YILDhjHM_E270p3yN6XGe_8zCAyjDEmXczDUry9ZNpFzAbrUt7UdGkrymBEhfIocl2ZrgGRG5nPEugUvQIDUG6m8Uk1NrxyNWkam6fLMfoBAymiBqwhliNIIz7-P-kpnIiTIKJLQPzmfTPAI1va4mfVxexqv4NbcTeH0pnShQvpbLmXdTQ7OAQ7edvTpRu_6GLAWLmbSZ6e152ACUPFTIDJRFX66qpdKMHm9dYYXDKUgrIvQU2cnl49yLnQ0sBfY-wTHVxHFWw6f2KX7EjAuXKB7kfzjttPULDe04ddl-coen3itiX_wbTIryuJyz6I1G0SuY=w1168-h779-no
44	https://lh3.googleusercontent.com/_gwDMT5hAjmMwmcY_w4Mdzve1Z-QrcXGtWQMllrJGKIxsroSCI0nWy2CBkoh7ZlxoGcAi0x8P31SIe2LCp8jDjPlOOIPI1OcP9eHdyrelA1npG_P09C-HYxmZ286Pl9gFgjJLQjwII0d2Jo1HKDY5fl3U5r7KZbxpNpP91gfv-DoB00anxwIGIma-x46KWWrv0LJp2jL-Ohmz2OiyMEMBYz6mJrEQ5Aqof6UFqOcJ63pzvJCbljLvkHJnXzoFMfgcLQNm1ooPbiE4cwxi0haOII7r3kYNxTCJ04V552Iv-ZLeqkqfJ6UIuBa_uBsSIJTDLlHcBc307LR45a6OEsgWAcezBP-cGShtGN6ka2fYXIGADTYRzhafn2qOhDXSesXXq80Tf3J74eNy5Jm-VxyNumOWircNo44AXQqeS5ERtDUg8POki9zcSoRke_3IxUj7VBv2GG8IuaKbclWOwYXhMN0zm_ox_zKCymirWz-NwwF7DmNvP9JND3ZbwtGu9qQg-AvaKQKeWfjmQq4Or6qbLGAqdp9z9OftV5i9jwT3AzIujJxLI4wfCaTjnjhJ84YAuStmkUxvor9kxUWTs436ZUaYheU0Yo=w1168-h779-no
47	https://lh3.googleusercontent.com/GtzFv6gqCh2JGcCeJOZNXXi_WO5B-dW2Wxgu348-qkONUHejtfTYgCwzcZPz0Iydf1prw2Bn3hfuuCdRymwPvuvTZGq20GQzlx0GvUeUFTIT7C7-JVQKLinqb9eptAfwmKUV7ppGEW5vbuETEWa0J6D3ysIc0lsdVoNiYNNvMCZ31bcJ4HsvXwHoH2-7tgyyxyuFIo6QWZP1b3B6aJyDk2PgNTbffI5p5C97iZ45W7QTp8TfZ9cMYMC83-e8GmsFHhQFC15eEEKctFYpmGb6LOKJf4r50U87hh_lMQyzPgoULwC7G-J75-XAH62gNpQCYGrS6V_B9NXqc3k-hR9WsS3mrRKNjbNzehw4ULGi0jYlGGrK6nhP4eHVZ-CbPeXY6SRONUl50tdzLU_IuB0OdoAohBrorKUuXoUo2UK8e53l6hyyofLNA_GUvqBGSnvVdeDLqgHM9KrxJVQMhZKEEvK8Wx_LGy1L1KiQQvUCIpgzWy3zxygQfgcVyVB9D4tY1tBeq6Nl4AGhxSLa2cz-IpmXjYlx_yqP8irHJoruK3npDyUt6AuBbdmplONkTyYeyiLkf7ZiNBzYRt62pj5KuOvKK6_r2XI=w1168-h779-no
49	https://lh3.googleusercontent.com/oKsonHYdAh4usvmApbbnrUHYUlQMmiIH1regBtqW78N6HT6wJaRV4iaWUyijzTcXRApnhcFOJmEiuKwDzNeVfRcosGbM2LAPWrO7WyAr6SX9QR3OYxlSBN68tjQX43wq5ow9tbUtOd1eKIvN3axjxGNXsgOLc-Ho-MRYWLIL7YHnC899-wIsCJkxLy65Vi_WvEoWrO0UmLBNGNVJrbRKA-PJjSSHKoEIEyYB-502ZzGK0M8sJhTH006zfq706nDU4OlcZs8_yCAowMSEVB1acE1YexzSrISTW9oz7qFjv8tTq1cMC5QM4F1vvXmxjsl4I-LMrKVzljFQME1xkXYU_spexcZ8zdXk_ABL9SknhmqYbMKR4ft_1sI5RTJB5WTGQiDSU7O_YhZvG3mXLFfLlICUEH_jMO9NnZvcDAQL_YkyASwhaf1rnsWgZj_KR7O24hrboi7ztQlJIipTFPJ83JViaIjhVm77uBfbFzhHmZ-uDEM_t2Hs3E_3-ZHlp6iLCvmnnLeODoxQNcffwsUOBm5UaOg6X_1Iyw-FXZxIXNFJk5mfLvmcejLZRaa-ONua7Vx_sNo9OlNpDFsPlrzAgQ1h2HXL8uM=w977-h779-no
52	https://lh3.googleusercontent.com/u3EhocAHiCWgz7a7UJQddvvpdx4FlVN92Jwh0GF3cdEcnoR3ne43A3uO1muHu_q2u_kNUR4MdCoJy-nZG0Bt0gKS30eSTfe5i5D1W-jLNsUYcHDkkLvnL1gFixVLDSdxVWoOJeGUna5pZVQ_1N3L2V7otZ6iHYgD2omoCcWKtbczss2nJSNS-KPzV1r7TAMaA1QH7xnOli1RLPvtC-4IpLCKi3Y8kDUOeNmD5a3ew_IqrA_F8vSnqTbnM3C_8fANXI4Z-TxDiyB2LF_AGz40cUXYAxPyxi_6qy3gAWabYrVFzQreR2hJUnKdM9NZwG4C9veD-7d9njaEKRUWUqGoMRJspzC5yK5aIRZUejJYd8RsRsqDTFkud88vv3-3KE7YyESLvUklna0WihDoQBrZXVC_e-rDI1cMH3DC_AsJmu4Iejv1D4TnrAC-TJUBvo8beE7tl-2exC1CkPvSgtqRTKhWydkszzV0CHdjCs6bFyJuAWcKyhjDiqr5YbyMhDOTWmWvYH9kQ8bWyxROfGWvgdP_BcW-j4nF_t2GKijKooA2HAjNcC7iGG4uzEyDqDNa0vZtu6CCwEptcXVwINtx9tnojOHIDd8=w1168-h779-no
58	https://lh3.googleusercontent.com/YZzOkcX6hLxMniZ4HMnpL6vBj1VPENmRPtggdw6Af35deG9tDChVccaV73QTZRzQuStrNsL54lrwol2U4XQBIgFb4agcnu45PMJKWGi_2ox75sPpVuC09LdTrZfGhb606vy5342RIkrb1C8oPSKsK8_ZLOvT3KN9OUiEkO12tYoNbIzlgwSxDt9BVwF1CBUefuqitM5v48Bv2gtEgIr-bfPNsv5Q3aiwFtShNh8fCPMkSx7qKGh1Pzh7PfT2dXmIhgwMQGcFH4EmXzW8U9Zo9w3GDpJS9ntTTV6LpGR7qpS3nFjGWaOGHaUm2-06XHi6o-MTwE5H2L3VRa5hf1sQWgMLJN011AsBSD2mbMbwLU37kuPn0QgmiwJbgbjoDcq0tsJ5NSbjQHOlWO4xBVlu18MstWz5s_zsOEtsJ571tEvKAo_rM-6Xm_1_4h5Iqu6e6ooe0cUxVSpbHqSVI0OAKkvYPNqFbDeUBzwd1HfDomAHchp-PTwrCEzFuWGJRuAiNbK879MPbmeQGxTLXa_YM6XKJ3bMFoeW8Ad4TS5sJ_ANdEAKLOpJ7ix3p2u-Z1rhubZpHsbFW9a3nv0wiFGwyHNk6MTwVHQ=w1168-h779-no
68	https://lh3.googleusercontent.com/-3RouE5e4BoI619mavDUwjs1PjvSPp0jNsx1Z8qBQXPK0ItgqSfBnv3SG-hR06OeBVYRFu-rrJkxGieS4Inx6eY16YSsyGX2obDEhVJYe0jjS-MP607GK25idTktl5qHPV1YP9BQbem2LOn31HBeDZ838pf7DQwUveX7eHwh7IdGLpw6n2mn7pQG8Nu6OeP5mqpNuOYkvumC4fZ7M0g1ytXqX3RbChmR-LofkOljbuU7z2_eellCmQT63snHkrJfwgWlf-hc_OHoqHUTBQ63B4226Rw-V3BnO8eEDoplwVTMyJ72bE9lttjd_5mwP6DLcOrrSl2xG432HjI0mMfu1HlZ4y3yWpv0D3f6KU4Twumgy9EFp8sUkKP8itVTk6VH0euSrV1AarR9c85bCL2KWukHb1t6Q0MuJtM-JBWZwPSRb27Udny5cXwnZ-l0h9mRM16z0RKDXn7vM_RcOZ6gWeXvEe-6QhC4dIZWyd8oxGdcU97f7qfY88XeO3AOmSwQ3Knwm0Wyy1cwwRsyZ0qvsEUTe7_Kx3Xs9wEnfU3Zd1253r7UXwy1pU3IaOcKI7T30J2uX65w_CmpxhplSKh04UEGFlQRTNo=w1168-h779-no
69	https://lh3.googleusercontent.com/AC7qD5ashDweZSZuQczCoMZhOtJbY2s1HT_s_TVMEtaQRT97DJ6BM34SZu7R96AaladsOlPC_HyUNTLPjY8m3umdHre3Ch3EMQRNW-LiTphSYH2RR9k5csdwMHD6lX_z7CDY8PRmnQO58lbp25e4v6WCHF_cICBHeZoPi12Q1_quqwyS27Ec7Y964Ta4CIJq7yR_FnP6St8WaXhk7nTb8UkAqYNdwqT6QTx2sHdVXqRmhMzApraOS9pFPDijls2cVOXBaJYWaNK8wxVRNGKb9w1FxpNkE3GZWmA7YXjN41UhnaOTApPbQCLs8xQ2okDgv8TRmV-Wr_apEN0fcr9ZPCuc5KW6AjUqicdYZwXkKZzX39NuYsqZ--5m4xDgTZrDSMoaYme5h8Yrc05OTWpmv0a2LxEH0WjZyyQEwjYEyg-DwQL8WfHLwFZUQJcrXxYaJ1LedbKWgB_5VpLO8aLUt7eGVJt6yt26VuupoRz1cNE4vEjBXbJJF-1bfRw2cWuSNTdtmEyo8KxRwH6J6cu9NbY4gR9rMZFR-X28ZsRAol8kUXAiBmaYqO15df8h_4i8DZiB4T-E-suP3HXF3bRH3-gcVqnWHHo=w1168-h779-no
75	https://lh3.googleusercontent.com/fqJUvpIlBB5OyloDSAR0Eb_JRSdL0PYp82vu_2Kgc5-yMCqBo2tCe-LaK8-7qWwUWhqGMYq-R-DGTL6SWlsiK4obr46vBc5rybp8eF5ZrP32xL3uEecjLtx3bSQgqUj0KZaY3v0-PrYpBk1GL4GsyNdml9JYcx5Zv6DTsvYOW07ffDY3AcfTJ6QnrcllRjXkK71JiWQq1ivM-UYIA_6975uxnglyc08GfycptTBoZlktz6cegn1lxLRHKSaa-yh8Xvuj6LQbfB7N2tqDlTYbMq5CD1rIAToa4hWiZ4kh2wPfz4VNQfWFR7wNJLpuG7GPj7stB8o7JIlIuQILQinnqBHFfqn3NqV2JEryYjN-oVp9mz_fgOOXoA3AGKEsRw9rtjPQMptq-nBccoE48OtzF6ZMHyV3BGrH3fESwOwgl0Rhipww_-34IceN__E1dhMPnH7SeKNdcI-mHy4o3RmwH6jwMQNRQ-UoQi-gvOqx7vCFSjlB2d_lKA8_QNX_6IACbAbvOyTjYj7MlMhVXHeSfKmVgHiB3HBrF6_eQCU1zS99MXmaHnkc9R3YNzTLtpFmWGUb7GXGh1hmEvdGP7q01l9qkaIzZ0M=w1168-h779-no
81	https://lh3.googleusercontent.com/iN0hlDfMObWmA5f-Jcvuhl_FzKb28fejYq_L5SQZvLzpbfu68Ai4iw6Iw_8ExsiwsSI0QpY-i1O0DIAwd2AgLRbmiEVnONgOBaEek-oROBGwzGlxQevB6e8Sb0wRCb17XZ3fnNz2Q72AN01j7vm1sEJ-xytYbMXkjvtY15u4FZI7kJ4PKPyE1czxJ4r5NCXRlFMwR9Qm7_7CKIHDntkZ1RpnaZwyPt-1ljOCWnorDWjdyhtyKTBZjVgp7Qu2SWXAzMHEFEwBw4kKoLXS6bcbFCE-21WGcsWemToGu3JZpWitPBZ2B47_Dzj6nrA15MUUKeQNr0QOzLqIRRaw_OzQnqqww0PXeh0MnI9BNjJg5mkG-Wok9IeSd5JhddkXeh6etlRc983hVFTM2X6TkMOWcp_4P9ks5ua4DOhSGZLmV8UEYHp7CxNSHljfBlc7MAoDo_Z1bZyIoZjGoLhPyH6K1drpmH2BwQTuJMOgPC8VXAGmtnAA0bXHop8vqaQ9CTVBe5AxmW8z5EIRhS_gdMeoKMf26ZBFp2kH9nVgc_q9kCrrA1HsfdV6znaGtliPUGOrBqtkBFucVJydngDMSYff8J49LtEvmB8=w1168-h779-no
86	https://lh3.googleusercontent.com/A6KSUStMc7oB8tF6psOVcPw4Dvx6EjBRYe2ccOmRlu5Us3dEg1nquWX0fOY0V-d7t-ybqIq5mwziPxqxCruyulhVw5QtLX5EEOgs6rSPTjHXxWxDYTMOXJ9ugNRU2Zk6xBUpk1i8jg3op_hSQTBE-6mg5k_B_AKQBRAHYPHyhjGz6wkJNOwM_iQIxW8EUQ5rEwYR-pRRhW_8kGfTTtxLeAGn3_zEImPgOKWOIIzE-i7R1aeE0DZro0YgyuhaBkjKAnCUVHDy5t1369Q9Mb3ivTxWyybitg1FdoMDWXw2V5wLx7TCa5GS0IQWFo_KsMy3DeZKyCntdULDVbkp8FZq2UtbldspZU-ANhWkS4Rn9NSQ5moIZIy6b1cdggVcLNO6ONFNymg7WVvSJLUyTnNoeF9VEiSogq81-mONM2_fTnFfs2bQS0iFNV9fezj-LRV7vGoivqrUTNcg8XF-hRRdq1_Gty3XflN9f7wE1805kppqQi8p6zFd5mY0HY172JTQD83zlZxB3Bp1LXFXxBpybm7xNY5U8WTDfZP9c7CT_mnk1wG4sSfjJg3w1dnn7rQXlyU29fAAKPz-KeemDvV4shRmk3FTIy0=w1168-h779-no
89	https://lh3.googleusercontent.com/9ppt2NDAzSL1h0LDqE4c75B4V3UxdOm2C8dYUlj_6f7-O4mdxYWZ0IkurLa6osEXL_4aZ2OqeVH7fcwEt9sQQJ0dGYmVEEeuGB08t01G8w9cXr9QD_s9TvLrwhQri-j8D2q43uRkYTF0TjUbxBGggd3rEOQ1gPlq9Uw1NFSFKPUs36h2v4E3MEGeRtInZpm-prXXeDxIC2M5j5zExSNDa_F5hP002iFFiA8FjHsLd5_fTZLqv_vOvEaA3jO8hJR33SCPHuxBHgyTmntxdDBU-o9OEECT9MlQtA-2aFVJA5dn7crCGjdZ-P27aJrJ7vpK4Ma-z665IxgGmMeb7xcPDlo6eTLvlfsX29uGpr9LIUq1H-_txVxxau0EVx7NWjuxxZnsEV41DwMRsJl8J06_mRlcnjVer8ifakSaLNtY3IIMjRsrGw2Vy7W69lnBw3hqZHZ1nzJ8Bh_BQxuWk_TqI9mQBxyWCiguLTpW6qIKdVIWRghy5JGCiM8FfXLESoNPh3-xsH0uaVYZLJJlLP2KAkAUTGg6VDwe8cP1cqIa9ehSqJgTEVCRlWrhEeeowzf4ENL7cI1FvVgX4X7gZjRYaj8jlRtoqG4=w1168-h779-no
50	https://lh3.googleusercontent.com/bDEFQFn4oz-0el_AXH4YWIH0SsuTWhQ8UkmtxBSWJxMhb2Hn-PARqCWLdvq0AiLmzvFQPADDhXgiu5HqrfkLLP75L0hbzlWLJGtUtqYFIUNw4ot0FwMK9kz5PQtOABszgvcWkewomC5KFOCtQzMf0o3FOFPR-bWxF7Y1gNgSIS16wWAdzYkl9NKYAY6Q2PZtXnXIg7vozi3DFgDLhzcIAlPl4TYD5q-LUQslCO64FqA8fmUtQlZvUZPzL1xIwUYuBIq9lZ7k2aZR_YOf-R-9vgb4YVa33P2vcMcLkqK6bpM9s0-xRoylNM3SapOiGoC2aZQMWdWIbvzuzUZSruydFDyi5bwuy1a0st64SSutunmuZjgDajy3rIFETkMupGdaqP--IjzZOO_qq1jvwYn-n6mqcJSu-Ie2OsZF0lYHNUFw0kzkXwe_yHSbGb9vLfEetU5cgxaLS7fOzMnPGlG5A792rrs34oyoKjNAl0l5Qf2u2tfohwMuRBZJAa0YkjGVublZOc5SSbCr3DDHaOslA3aw5BOZYzoNLITkOo-c_kNFu9OJhXGT04SEptgv4lh620dP3y7Fdftj_OhWlthsHPbaVWH92eo=w1168-h779-no
54	https://lh3.googleusercontent.com/HTldJ-xMuMGKBI_z5Fmyb3XczUXojB67LHZvinl5DPOuHRBJVSwxPVfSJ6cpOLJhHYWMffu8WAUJNn5-Mb-U20C0EjIoVkfP2GfkOFX_aj6_mPB20pG_HKdWy5PNw8ZEOEfFxtQ08Mrp4FaymrfqNRp-cnvczuVzhZ-xvfhCenhr9KZ3m5gGK0N2wVLGzyxwZPZNKMDWKxdXbWuXhnImjQnjZdzkDPHAGzNV_LOPpM9fc26xTahCju_vFDIazauj8Es_2v77BIr_ULLAfPxF4UZhnmi_aU-btBt0Qaj-i-yKvLw9FvsWbUTO87VmRGGyPYPemGG63PuzAQCp1rtAFgLa9mFpV5iZRXWqZc53tBAHD8wNSHDWo5hrBYtrbjwqAXNT19SQgMqBTWmAc5KVoGQeWhOkGOU9BPRPU0YPTbt5bULrKLhmtu1pXDln_3wEdSJxvbUj7vg5GUY7SSGrLC_XYFBUf9kugKY8DJKCpOxwmxOVLmxnPuZHwjQkX0Va_M9TfiDO6m5qLi8naG10T5hKfm1Ih1OqFKs1OAIgj61mZy5N2aOwk6yT3xsKQ_QvM-07H2TpRsdLkbj1ZywBwim1O-Fyifg=w1168-h779-no
59	https://lh3.googleusercontent.com/gt1uamRheMxmW1IbMXigqDMYZAgiY16lxhRZCes7clrQK1qtJsb607yF6tsx8LSEP-2GdJtNV2gPju35SLvd85eY8SrMN0JO3ZfoCP59eVlulW4VUDzUyzRCLyGZ1vXYL92Ju6fJcUjHXvRxcKU4sVQ3sVTswfNhorBB5-Hx_XWBPA1lrPbZHa6e0UxZGwpM3vHt-jTjNkojeomq6sYFR9dQPJB5y-jQ_3lT3V213YrTtzOG2Syj6HcAq8S83kG24VXLPCq2j7p6vVf_GwkOjvltZ9HykevKKb9k31NHrX_cMZ6kf0cx27rGqBseNfbpcxAwI7FZPtjH0QUW0Focrq2Q6Pire1UAIa7gKc2Qm4xFKjHLl_bZo8Z9vCJ2IUREf57iYs6kbDu-n7EpshN3UY0gfSC8OG79q6mU4jsw6eCrBDOqsfKfG8OvFc-j0k9KFzT_GuBIbkQ9K-hCXTlInfA7nFf3S_fsctoM-XrEYyqeE8oLfGTLT9mu2tq-3WqjfgVA5p6XJMO4F1-wbi-OIMG2hEV5ohDqzQb2q9p_H_m1lPFrKD2Udysg4iBdEzHiKBoi1_tPXAI6eBlu9s9BuUPVMP-Prsg=w1168-h779-no
64	https://lh3.googleusercontent.com/8YHvQ-HoUAID5MlxKhAF7WJ-nfGKClXWsfCBIxkMvQ4cW8dKiba6NtvsqUaS1yV8dPQ6WpY0TRfGhaLWCb9pp__KyZNLTt2XWus34ri489pFinEQH4nXBw81RzNCNq6mFqlfeoeCskQ1S2BqJGzuDhIi95V03Q02ve66b41bQVa9j8gkObpwsPxPGb6OR1SaCfpBMdgAFlhQurq1-Y340VPVzS9hAKfZdulTYQBUWtYVWxyMWE80a2W_qtiBMhJEcrnhyAKSAew7WEryF3wNckNmTTcOge-y0ewlOL944IE4d9vWXWJGkFfIRUFmvz8tsvPo_lJjTI63nPqvkH7SfUZEOLNh9QZUanf-eIcfPMFskwiPwnxmkhThvcKvxQ8NjmQ4FGL_U14XdyqLMCWLyY8grrRLTSwExqtm99ehytJ1SzTsH-m5f-YcZ58ktm9zOEWQ67WJOcGWBTrK5ytKxPFlTpmKHFUsvsBowxc5IBc8qptNrZm51jhupf_eWVysN-9nSNj_JMs237udkMq_vdOWnepeK2xQr36llf18xwYHFYzZS4dei4TDXbZciIthpbuBQWJWMiZJr-xUPETh0tVUce6l2XU=w1168-h779-no
95	https://lh3.googleusercontent.com/V7vM5s8MsXS5MvTM00aUE_k_bApQqrHKWMuAoky4w6xuJMcnFzRMjDOTrJu6UH5X-1tD4TubOZn_h_9nFyajogNyGuDhFhciscoJo3KmBnHt7sTcW7eZ5ULQXCdutS4izhSaW002FPY2FC96MpTQ36C25XwgemMPXzXBU45UoNsChDvoJ5oggFXPOBjOsVOYGmlvuyHnuJ9aldROKR66YPDY1QRUY0xQP-zKr2Ng2MyJio1UlHNIwJWOQ-o0rLlUsNvFExMcl4ZmOPphPO2U91Lo7fhym7sYKtd7Lq5dUYeoUuSjK30ZYQD8JreZumROgkQJG6f9NBXTdtosgqK2TVwccoUn7EP5T1qrgpigS8Jr7XF5thwk7BSvrEQgbmtvwU2VUhd1zj2JkYh5Kv6PD0uarDj4UlnkoLuKm3J7PytDPessdO2vwFLWixKj15g3R4WQEW21ZOysVcO7nmDqmplnb4WXD2hs1RGohjkeALR1T5n16JP-Dfk6TXAdpcLPlNWCwKGmxZrEPThKzj6MHLlTxXW7XPGlgY6cO5Lfio__N2dlY7QLYG6_KAytLWvNAH5-Aa_c9WXfBYA6mLqyt6Qw0Q4ocPo=w663-h442-no
96	https://lh3.googleusercontent.com/ZQZI74Q23vOqCqwwxzXIRJXYF88TvxDq4iVNL3enCqexVubh-RO22GrmwLSOespKyWDGICKoL5ljuGdRnu7YKgckCQzxF8d3o83IdEWiS3VbNZvuPKnuIt-cCzHUktr62rFlMW7W6VHIPB-XkOgVyhZ2qTnTRB3q85nmi5_JiTMqwMNdD7UBCTLcy4EynXqUzzK9z40VWa3Kq8wQDVK5p8EhlchV3qSUl2pVkMGx41iZbE6A-C-IEP-mxqodLAXW4sFEoGs8bxhJu_dv1WJ9PUrRY0cx5a9JtGNpZjaa2SvUkucHuS-Y0Jn31HlBX57FziEwFmJvoXb6Vz2T405wZi5dXRxuVsb-TmXRf8vtT3pxRxQnDrOhF5z_VoWNaLeEhJuGUhQt1zfYYKQmHR-KjJF4tYtCkmkFgThV9hA0Ua9zoZI9SYF6pOGmGuUCafWt9SeUvwpxZTsSfzKn0g9pc9kI0UVA65R2XYuizP9ci-tDXbFw83pDC4PZh6Oi2QpEpQ4eKod45QFd9x9tsE1WhY_SKyqTzIWUpujwaVElADrMdiZAMXnMBiUnH2hwc9r2wZ5zYaDs2K_RIg0cuKpuxK-KFClB4i0=w1168-h779-no
97	https://lh3.googleusercontent.com/HuB5NOPBkzKOVEEcLjQJpwWqjEkpiMbY_CcxppF5hB0mzCZPz_H3GMFDyVu1dsOVXerjIuhfo17Q-X77UxyC1NCD_H8cEDaMTCA-hSt53B927IZYrE7BY4AD8MEywRCuohvw8t6HQmmHCRCoyoie_UXKCEpDckfqzcHKbe_9dYFPonG7xTMCkFBfiqyKOq_tlyeqo6QCQIG85Wgr0H3MFEQklHuxOCSstNI6b7K5toJjnhOd-HnzVyTEgQzWIy9JkL_AyntbrZBqJdSp_sGAKZcq7MLdPRyWGN_ML82aA4Cq5CKjtA_rnzSKWWS_kwb49IMQgHKKxu3KVLvh2fxdN5Av6DmgXJ9_fzyYmdA8IjyD7HwK8UFhXsjY3auBuhzCotUbuNfT7RcfSl1K3uFakU2P0_EIs6G6sPqa7-JqAOXXiiesyk_4tQmSXPk5V-T4AoVylzZJQ7khuIH5uffMm8t9AEiqnsi0565cO9aZNI6E8wrTx4cX3YAjLwShLQ9tcVFTdOKxP6HSx6ep0pc32lEnHvVTSiuXyxed0Bx8sPuqLiRk93TgDbO_y_fLR-bTD3xVfIC2JEYWnt895rkvBbEfX6yAAPM=w1168-h779-no
98	https://lh3.googleusercontent.com/28Tb2cKmtQENkQ-JymuKWvuPJDtW1UY6YN72pv2Ryvkl_zBlXiJB95uVU5Mivxo6xBIL9eQklsDRXF5TCs2P_txa3M89PKpfbdcJT13e4xktqHDD-RsomLSWaHe7o5NDUqDRrbt7LPj_WnX6pgqdSISMLDqlMrsDeI__GImvol-CHXZVlBcCUcXWF37HkDxteWZxQkPFEadjGe6VLghopXFupCcGkAnbtzd69UedC4GbNIdaCfI-fupNH3nGMcGlix-h3yeXyTzAlBNX5RNM5u9vsB23Ve42vmDtd5COWGjsTY8OFxDyRA6xb92T2giF0JY3eGtlorLPr-141LSG5xrrS4aHnuqZGUo1Zu528z_nKG_E0cnsxzqbhM-rk5FKuX2ZG70zLJshjZN5raVNXkRWAHH_0s3Uc8K069KKH3dULdmaYmcpZeT8aIT7XWW4fknrNTt_xpwAsfgHFn2qhMkrmWFvUXNEvWPZSa2rTkUFU7_7wLP8c_spfXiTW1HEKx0DzrSVaBvoHwvoklg8dhuHy_9E7oJ1ahVCe_UDIDgxk89gzdESl8MUO5Ys9CYVRyogOH5WeE3E0YfQ6BRdRzRJKWwGfxU=w1168-h779-no
99	https://lh3.googleusercontent.com/Hr_KqVK-0PZGcM3QMw_pEizxyfpH5xhCrWLaF-aiUz2CZTlI69PMpdSELj-i5sNOq2e9QB6iX8x3I8fA5u4put-ZmOj6tO0yBErQ_VcJrs3ni4yluRVg6UORjr2tza_LbLHR3cl05kYmbA1by_5VVf93xvdj0P3zIXIj2pcNFTYIRUjcowycT5Goq2gMGwuvjrxlNI498lJLrqgKYMlXOZjGyDMnn20K5_vAXYdBLwiD3ifRZxUDR8JDzg3raTaoD7NsFhDFC7O4TbbyHnVNi4KttlQzGhOUHX9hR8gq31UVrGPIGHR8EmaRv-FUzOrYXmyvacYRS3QjzpArGeRedBOIqUcCepMX-1daD77iGhAL6TXEuLP7u-JKD5nRuUIr7LPf7TPHoLVLqSLe5dDRKX6OKQkta8VzJNAeYiCyPKfyhsWKWGtEpZGuQXmPwMYZYAxETiDjk9A3WBodbPoOiSHUzaLGNx9TpHd3Cv12sjqCDCdkJDykuRAJw7-zJjAZXz7YUzW9sQcf5H-vg5ITMiTy5JrtkZCfD8ybiztLi48v3fhuBOQqe_xkyN1di9EYCtbY2hB1G-2aHsMG_JQOdIM8p55Vcco=w1168-h779-no
56	https://lh3.googleusercontent.com/FJikhe1geXVpdhcjPDbK57dJ4YLHXuqihePG-VxoXgixi3yYsMyjrAv3v2Y1sV0MK6M9WdBcBu-VutSlWU9tpXiy0z9ObDEI-QaoUC9Y9ysUXB_aQVYGKlCvI_EQFNEPn7cuZioPhcUrEU3laFhYr3B6Gi5_TNW70n4DDbKxKD3F--6wH6727-nuGDPp5LyskSx5U59srjQOasiFDVLU1u7GASLrkwBDEjdvwu6ZoHCe1FFZ_uLE1RmAB7O2JMw7rown5q1oQrQEOLRt5WHSuU_0zBmGTVzvT1xNQy3CoxxAoLt_PDyQtT78cUEAasRyN0UdUG0kG5npLdjoDBfgoTt2bb3oWjgIV_D9dHbdE5_nH2-BXeovcr7kgrUOxSI-4gLm6-qGhB-xpXgWrfLPGnzXuxARX8WDc0hbf7rEpy0GiaQeXlvmVsG5IeZd1pk2CvvyZZbalMKqRo3yCp7jAUQHdRxLqZGCbjqMlO3zoZkDoBilx6b7mYG51Eq48Ntt12SWE_ozbPdvduUOIISMvKejsdO-_Y_S5qvJJ7ysOsTucogpuvMxAQdGZpIw1pxZDqoYnXEB1IfFGiqzVJrMUmfThOKbjMw=w1168-h779-no
63	https://lh3.googleusercontent.com/hdjLs-R4mRig4SP2gQJ-y5mmXTT74kDk_XsYeK8iKdYBQoJjMLGm4NjjT994_ltIppr32Wo2GwM2yTXdi60IUm_NkgliJxiEp_V5m7VQl_4Jy9j30XOr-N82jiXChHxPBQ-VuF2DToETk6MazQx0mU3T5qZg0KavuSx4cEDj1IT53gabBipGXkBfZDHhrz7BNYnEV2QHHLAhXiz6pLPI1yE7xKJ_wteMHQ-8-XhsyHib089kn3ZTfQ5udAo04mO0vm1lr6UMo0hxKG8mmD6BSF3ATZtWGaYS1cZoR88tNzdiJb0a3Xcq7xD0lQsJLZUdYEBbKrxlj9SZuCVHTLQl8mcdaSuT31iKQdsSP6u_2WdT87VN5I0TRapV8nelQNQg7FctBjT3DLyGuFk7mklmZLY_nGHrhije8MdOgoM_T4jUJc8GAa8aVgbYJpmKC6zS7k4iZCLoaQvv6LPXel4l-02xURSOTh-g4-mIqVV5X9HjDIsXLBGIL11AAJssTepuIjepK9y6VZe0qDn3IFrWGbVjhEROvgeF3nWJip7D_PoveS-myihYJmpwOmgU_voojP77fgznQ-5l0W_caBmtS1prRGxwI18=w1168-h779-no
73	https://lh3.googleusercontent.com/l8YUn_H2C161Btx8t5m9rpbhqIynuijz4jARt0yNFOb8fZG_UjArIuQ1ka6dZQCtehP-mpM_5rJJNDOrq1Jgj4ZFp5rOY4mPJFAsCjtdAOYZYu2Lq8XRPQbCacQ11i_PHdv7eULEFf2IRR-stFOHOa_K6iqs7JGZUoVhLNyPww0gn0bYFbhVF5itNaVlig-7wENm2Lywh0NNiAYyosYe3neJj1hkC5QopWQeT2eCUEAg_PJZ_zGvo0ZBrsCKpOaOpCAt2gkF-XFIZQtFYd4_HatgJe3tXlBQpA7Ki6opyRXJkzMzOsR08bNEF0fYI5p-ZKIQiuiBebPQZLVmqeJyYuw6Tk-hBBz4L7AdsxZmHJZOzP3YUKgTE9Pris2aqOh5OVGbWkCMonDFoaR2oM5qSUZ85NKQcTLjQxOVMKpzVWNxLWa5pNarfUyQi9PRuEL9TgW-jgjRvXgIogJIn20Dp5WA-7tcZ66K1DhGKuugiE8dee98JGarSKkaxAnEp84b_wQdCo2ohkQ0sYW05BWZ4iRAWtYwh1qFLkcrgBbq6icaBE1mdUU0wuzxemoY4qRQM6oNvbW5Knk2MkrzSLURaOMopuwuGJo=w1113-h779-no
80	https://lh3.googleusercontent.com/n_Jccp8VGdqPRSx29SFWBJOw-tME45agWe9FhjpQj326ya66rKlyr7tdwJ5sppTWgCj1GpKd72zttHEDIRnvPtoR96sx4XDXZiv1G_Zw1NzJBFepyzs0xcPtM9A_H_ESgTgGpssT5aN-rhC3RpZpoMGB3T0MDWJjixGY_dypuak4HS81s0ZEEIU5ClAaWNEcA_4Vq6PC-Eh3Udns9eLdGy7wMTpEaknuludTaYHaF1m9NGjPenP-5HG2whpznJ7xk1fxICRmZfLlyopWkXAJUq45WptwWiW_BXNdqogzfPU5UnDXgjw4M6RswxDU1XCpTrxtH6r_5Q4ztJ1V74RdtDtF2MPa8XNRfSexOmkpMhnMzROkWBxqYtrjKhnfkFLUTtWkkiCuCcsv9uiWg-TUjOmE2kJjtZkky-zrWIN5FIeKxWv4UyhR1L9ItlRm7ogGpl1Q5pTf50cMw1A272scq9r-eV9FTIzozDrXCAn4AIStlELvnJBos1yU4K5eDrZfSy-CMmzxojncxOcPluWxXZ09YCjt0qcJ-x0VIh-WlS5_mzEGWtLJD3oVgy-9JWf5A-OX40ujgBHEiBt7h1L9roZE_h7AeYQ=w1168-h779-no
84	https://lh3.googleusercontent.com/ZUdW9J67zKCp9G7gb-80LzUelytEyRfvsE5pCX5ElrqkukyZ_VDljKRpb_5FrYVNcQ11ZcXfuY9ceo3Ml1hcOgjMKbXZhrpPzQA7fZiQ0mUWYB5Q1rQIW6jBCuipABrUYILCGex3mTwIg2gvG0Du2yTDVLP9MVV3lqjJVkC57D5ksoAmDimLuXepnTinHoagUMiUMGJH2P8wsvLtmKbrO7ROIns6eIjTdb7FI0Uf46b1dzjI3MRtz_IF8E7hkGX2XtcOzJnF3OcvcVMsgOE_PV8nvsHYkVipgIbezgTqJEwFdi4wY2YTSbGm9lxFPnq0f0b6C62lumir_PmHP7MptnOPWTwf1FVVgTGSrEdWYn6y2if64WdyEkc5XosIJTgCEc3iSRE9ChgJQTa6-0c4520j93wtj9Cm5IwcuxiHAqBWXEcLEkeBCS7cn8VvARgLYgW6i5U-1rxlJ8iwP2QBd5qg4dX97Qo6mcg9LzkO1PpEDcvAzDWov3bajQwkt2aRe9QLIQBWPMxo0-xGhHPGng0CmlqeQyzcSBSYST9QRbHRL5LofgViK6kLgzaSE
\.


--
-- Name: photo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('photo_id_seq', 99, true);


--
-- Data for Name: site; Type: TABLE DATA; Schema: public; Owner: -
--

COPY site (id, heritageitemid, name, suburb, address, latitude, longitude, architectural_style, heritage_categories) FROM stdin;
1	5051403	Experiment House and Cottage	Harris Park	9 Ruse St, Harris Park NSW 2150	-33.8202424	151.0127663	Colonial Georgian	NTA, LEP, REP, SHR
2	5045475	Old Government House	Parramatta	O'Connell Street, Parramatta NSW 2150	-33.8100141	151.0010549	Georgian	NTA, REP, NHL, WHL
3	5061073	Parramatta Sandbank	Parramatta CBD	Robin Thomas Reserve, Harris Park	-33.8170928	151.0123877	Ancient Aboriginal and Early Colonial Landscape	REP, SHR
4	5051406	Roxy Theatre	Parramatta	65-69 George Street, Parramatta, NSW, 2150	-33.8141507	151.0042441	Spanish Mission	NTA, NE, LEP, REP
5	1	Elizabeth Farm	Rose Hill	70 Alice Street, Rose Hill NSW 2142	-33.8210509	151.0178942	Australian European	NE, REP, SHR
6	5051462	Billy Hart Memorial	Parramatta	Parramatta Park, Parramatta NSW 2150	-33.8087399	150.9949473		SHR
7	5051397	Parramatta District Hospital – Brislington and Landscape	Parramatta	10 George Street, Parramatta, NSW, 2150	-33.813179	151.001785	Colonial Georgian	NTA, NE, SHR, LEP
8	5051462	Boer War Memorial	Parramatta	Parramatta Park, Parramatta NSW 2150	-33.8087399	150.9949473		NTA, NE, SHR
9	5051462	Dairy Cottage	Parramatta	Parramatta Park, Parramatta, NSW 2150	-33.8087399	150.9949473		NTA, NE, SHR
10	4301684	Gasworks Bridge	Parramatta	198 George Street Parramatta, NSW, 2150	-33.8161895	151.0141487		REP, SHR
11	2	Governor Brisbane Bath House	Parramatta	Parramatta Park, Parramatta, NSW, 2150	-33.8087399	150.9949473	Colonial	NTA, SHR
12	5051462	Governor Brisbane Observatory Remnants		Parramatta Park, Parramatta, NSW, 2150	-33.8087399	150.9949473	Colonial	NTA, NE, SHR
13	2240368	St Patrick’s Cathedral	Parramattta	1 Marist Place Parramattta NSW 2150	-33.8097763	151.0033497	Victorian Gothic	NTA, NE, LEP, SHR
14	5000	Parramatta Correctional Centre	Parramatta	73 O’Connell Street, Parramatta, NSW, 2150	-33.803447	151.0031959		NTA, LEP, SHR
15	5051462	Little Coogee	Parramatta	Parramatta Park, Parramatta, NSW, 2150	-33.8087399	150.9949473		SHR
16	5000658	Female Orphan School - Rydalmere Hospital Precinct	Parramatta	171 Victoria Rd Parramatta NSW 2150	-33.8117675	151.0255869	Federation Free Style	NTA, REP, LEP, SHR
17	2240207	Woolpack Hotel	Parramatta	19 George Street, Parramatta, NSW 2150	-33.8132438	151.0020727	Colonial Victorian	LEP, REP
18	2242863	Lancer Barracks	Parramatta	2 Smith Street, Parramatta, NSW, 2150	-33.8170246	151.0059519		NE, NTA, REP, LEP
19	5051462	Parramatta Park	Parramatta	Macquarie Street, Parramatta, NSW, 2150	-33.8154713	151.0048428	Colonial Georgian	NE, LEP
20	3540613	Wisteria House and Gardens	Parramatta	Hainsworth Street, Parramatta, NSW 2150	-33.8035823	150.9943884		SHR
21	3	Lennox Bridge	Parramatta	Church Street, Parramatta, NSW, 2150	-33.8141172	151.0032407	Early Colonial	NE, LEP, SHR
22	5060990	St John’s Cathedral	Parramatta	195  Church St Parramatta, NSW, 2150	-33.8158545	151.0025935	Early Colonial	NE, REP, LEP, SHR
23	5052762	Hambledon Cottage	Harris Park	47 Hassall Street, Harris Park, NSW 2150	-33.8187546	151.0140638	Georgian	REP
\.


--
-- Name: site_heritageitemid_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('site_heritageitemid_seq', 3, true);


--
-- Name: site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('site_id_seq', 23, true);


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--

COPY spatial_ref_sys  FROM stdin;
\.


--
-- Data for Name: story; Type: TABLE DATA; Schema: public; Owner: -
--

COPY story (id, title, blurb, story, quote, datestart, dateend) FROM stdin;
1	What doesn’t kill you...	Long before the age of sterilization, antibiotics or anaesthetic, medical practice in colonial Australia could be both gruesomely rudimentary and oddly progressive.  Mortality rates were high, dysentery, typhoid and venereal disease were common and a healthy diet and appropriate medical supplies were hard to come by.  Spear removal and vaccination against smallpox were just two of the more unusual services provided by Colonial Surgeon, John Harris.	John Harris arrived in the Colony of New South Wales in July 1790 on board the Surprize, a convict ship with the notorious Second Fleet. Harris was shocked by the squalid conditions, disease, starvation and misery suffered by the convicts.  Upon arrival he settled at Parramatta and in 1793 purchased land from James Ruse and built the cottage that still stands at Experiment Farm in 1834.\n\nOnly three months after his arrival, Harris accompanied Governor Arthur Phillip on a brief expedition by boat to Manly Cove. Phillip hoped to meet up with his friend and Eora man, Bennelong.  The group was well received but a misunderstanding occurred and Phillip was speared in the shoulder.  Harris offered assistance until senior surgeon, William Balmain, could tend the wound. \n\nLater, in 1818, at the age of 64 he accompanied John Oxley’s expedition along the Macquarie River as the expedition’s surgeon.  One member of the party, William Blake, suffered two deep spear wounds when attacked by a lone aboriginal man.  Harris was able to remove the spears and dress the wounds.  Oxley had feared Blake would not recover but later wrote to Governor Macquarie commending Harris and his invaluable assistance on the journey.\n\nThe medical chest and textbooks on display at Experiment Farm Cottage provide a fascinating insight into the common medical treatments of the time. \nThe Simple ointment contained was used for the treatment of chafed, cracked skin, often suffered by convict labourers.  Aperient pills and Calomel, a compound made with mercury, were common laxative treatments and indicative of the need to counter the meagre, low-fibre rations given to the convicts.  Harris’s chest also contained catgut for stitching wounds and re-usable needles.\n\nThe colony was progressive in establishing a vaccination program against smallpox and in 1804 Harris placed an announcement in the Sydney Gazette, announcing his availability to “inoculate with vaccine injection”.	“Harris’s chest also contained catgut for stitching wounds and re-usable needles.”	1798-01-01	\N
2	The ghost of the Governors wife	World Heritage listed Government House is a special place, not only because it is one of Australia’s oldest surviving public buildings, but also because of the many illustrious people who called it their home. The convict-built Georgian mansion which stands in 200 acres of parkland was the country residence for ten governors and where the last governor’s wife, Lady Mary Caroline Fitzroy met her untimely and tragic death.	\nLady Mary Caroline Fitzroy the wife of Governor Charles Fitzroy arrived in colonial Australia in 1846. The daughter of the Duke of Richmond, she was well known in the colony for her charm and generosity and the Governor Fitzroy was every bit a man of the British Empire. The Fitzroy’s were seen as something of a relief compared to Gipps caustic ways.\n\nGovernor Fitzroy was well known for his good humour and joviality as he juggled the backbiting and continual conflict on the matter of the continued transportation of convicts.  Fitzroy, rarely involved himself in the nitty gritty detail of public debate and focused instead on pleasing the people.  \n\nThe aristocratic Fitzroy governorship took their ceremonial duties and Lady Fitzroy, who was probably better connected than her husband, was well-liked and known for her cheerful spirit and generosity. She assisted the church through the loan of a carriage, rallied support for fundraisers and was fond of both hosting and attending the dinners and balls that accompanied her role. \n\nWhen attending these many ceremonial occasions, Fitzroy a keen horseman often chose to drive the coach and horses, which not only served as a mode of transport, but also added a certain pageantry to his role. \n\nIn the summer of 1847 the Fitzroy’s were to attend a wedding in Sydney.  Much preparation went into the journey of some 20 miles and as the carriage drew up to pick up her ladyship, the horses were observed as being skittish and high spirited.\n\nBefore the Governor had time to settle himself and take the reins the horses galloped at speed down the hill.  Lady Mary’s screams could be heard as she attempted to stand up in the carriage, then fainted as the carriage overturned.  The carriage struck the oak trees sending Lady Mary crashing to the ground, smashing her skull. The governor looked over on in horror as she took her dying breath muttering ‘Sir Charles...’\n\nTake a visit and walk the driveway to visit the place where Lady Mary met her untimely death, some say you can still hear her screams.  	“Lady Mary’s screams could be heard as she attempted \nto stand up in the carriage, then fainted as the carriage overturned.”	1799-01-01	1820-01-01
3	Ancient Aboriginal and Early Colonial Landscape	Beneath the foundations and footpaths of downtown Parramatta lies a sandbank. Broad and deep, and known as the Parramatta Sand Sheet, the sandbank is one of Parramatta’s richest archaeological sites. Laid down over 30,000 years ago by fluvial action, a river erosion process where sand and sediment is deposited into bars, points and flood plains, the sandbank tells us much about Aboriginal life and early European settlement.\n	The fluvial sand terrace arcs inland from the river to Hassall Street and in April 1788 Governor Phillip named it The Cresent. Now defined by George Street at its northern perimeter, the sandbank stretches to Robin Thomas Reserve to the east and Harris Street in the west. \n\nSince 2002, several archaeological investigations have occurred on the sandbank as part of pre-construction legislative requirements. Excavations at sites in George and Charles Streets uncovered more than 10,500 stone artefacts. Axe heads, hammerstones, anvils, grindstone fragments, and cobble chopping tools were recovered from two distinct layers of deposition.\n\nAboriginal life here was likely rich and bountiful. Swamps and waterholes punctuated the sand terrace attracting fish, waterfowl and game, and the grassland was densely vegetated with paperbarks and banksias. Archaeologists uncovered a knapping floor, a place where stone tools were hewn, and numerous cooking hearths and ground ovens. \n\nDerived from the Darug word Burramatta, ‘the place where the eels lie down’, Parramatta was the second area in Australia settled by Europeans. The bulk of early colonial development was clustered along George Street adjacent to the original Queens Wharf. \n\nWithin this area is Robin Thomas Reserve where archaeological investigation revealed a covered drain and sandstock brick footing associated with the c1790 Military Barracks and Soldiers Garden. The convict-built barracks were built within months of colonial possession of Parramatta, but by 1829 were demolished and the soldiers relocated to the newly built Lancers Barracks in Smith Street. \n\nDespite continual adaption and reuse of the barracks site including construction of a nursery, a row of seven terraces, a shop and the stone Somerset Cottage, the sandbank conservation zone within the reserve retains potential to reveal relics and physical evidence of a convict-period military barracks and information about the lives of successive occupants.\n	“Derived from the Darug word Burramatta, ‘the place where the eels lie down’, Parramatta was the second area in Australia settled by Europeans.”	\N	\N
4	Hollywood and Hauntings at the Roxy	On the eve of the Great Depression, the art deco splendour of the Roxy Theatre brought glamour and celebrity to Parramatta. From its dazzling grand opening in 1930, through its various incarnations as an entertainment venue, to its eventual closure in 2015, the Roxy Theatre maintains its atmosphere of high drama and illusionism. It is said to be haunted and has become a magnet for modern-day\nghost busters.	The gala opening on February 6,1930 was widely reported to be a stellar success. Over 8000 people thronged to the venue where guests marvelled at the lavish interior, plush seats, guilt décor, potted palms, rising organ console, and remarkably modern air-conditioning. \n\nA major attraction in the new theatre was the grand Christie organ that had been imported from England at a cost of $32,000. The largest organ in Australia, it was proudly played by organist Eddie Horton, who encouraged the audience to call out or whistle their musical requests.\n\nThe film chosen to open the cinema was a modern classic, the Innocents of Paris, (1929), and featured the debonair and hugely popular Frenchman, Maurice Chevalier, in his first Hollywood film.\n\nInnocents of Paris includes the famous song Louise sung by Chevalier in his heavy French accent. In fact, Chevalier could speak English without the accent but was urged by the studio to exaggerate his seductive brogue, supposedly causing women and girls the world over to swoon.\n\nThe song Louise begins with the words,\n‘Wonderful, oh, it's wonderful\nTo be in love with you\nBeautiful, you're so beautiful\nYou haunt me all day through’\n\nHow prescient this last line of the verse proved to be! Since 1937 there have been rumours of ghosts haunting the halls, lofts and basement of the Roxy Theatre. These tormented souls may well be the spirits of those unfortunate individuals who met with tragedy or misfortune at the theatre: the heartbroken usherette who threw herself from the roof; the young boxer who was electrocuted only hours before his fight; an unlucky patron who fell, cracked his skull and died during a performance; or the poor young girl who fell over the first floor balcony, plunging to her death after a panicked crowd tried to escape a fire.	“Wonderful, oh, it’s wonderful To be in love with you\nBeautiful, you’re so beautiful\nYou haunt me all day through.”	1930-01-01	\N
6	Much more than merino wool: home to first olives and pirates 	So much of history has been configured with men in the centre of the frame. But neither Elizabeth Farm nor husband John’s reputation as the father of the Australian Merino wool industry would have existed without Elizabeth Macarthur’s determination and dedication to the cause.\n	From the moment the Macarthurs were awarded the generous land grant of 100 acres in 1793, Elizabeth was determined to make it their home. Construction of the single storey home commenced the same year and progressively grew to include servants quarters, guest accommodation, nearby Hambledon Cottage (link) and necessary outhouses, stores and stables. \n\nBy all accounts, John Macarthur was a mercurial man. Ambitious, tenacious and enthusiastic; Macarthur helped topple a governor, was court-martialed and exiled, and considered a dangerous adversary by many. Despite this, Elizabeth Farm was the scene of political and social activity including visits from governors and their wives as well as military and religious leaders. Elizabeth extended hospitality to all, raised and educated her eight children and managed the family’s other properties, including the selection and breeding of their merino sheep.\n\nTaking special interest food production and in her garden, she wrote of its yield: “We have an abundance, even to profusion, in so much that our pigs are fed peaches, apricots and melons in the season.”\n\nIn the garden are two olive trees, thought to be the first grown in Australia. John Macarthur brought specimens of the European Olive to Sydney in 1805 and 1817. He also imported grape vines and advocated strongly for both crops’ commercial production. \n\nWhile much of the hard work around the house and garden was done by an unlimited supply of convict labour, it is with some surprise to learn that the Macarthurs also took advantage of the horticultural expertise of several Greek pirates. Convicted for boarding a British-owned Maltese ship and ‘helping themselves’ to supplies, the pirates had been banished to the antipodes and in 1831 were seen by Captain Thomas Mitchell tending to the vines in the Macarthurs’ garden. \n\nElizabeth outlived her husband and remained at her beloved home until her death in 1850, aged 83. In 1881, when the estate was sold, it encompassed nearly 1100 acres. In 1904, the Swann family bought it and remained owners and residents until 1968.\n\nToday, Elizabeth Farm is operated as a house museum by the Historic Houses Trust of NSW and offers a hands-on experience. Decorated with replica furniture—chairs are for sitting in, and cupboards are for opening—it’s a place where Elizabeth Macarthur’s life and ambitions are given new life. \n	“We have an abundance, even to profusion, in so much that our pigs are fed peaches, apricots and melons in the season.”	1793-01-01	\N
5	For a Dentist… Billy  Makes a Great Pilot!	In November 1911, William Hart, a Parramatta native, landed his Bristol Box Kite aircraft in Parramatta Park.  The memorial, erected after his death in 1943, commemorates the first cross-country flight in NSW from Penrith covering the distance of 18 miles in 12 minutes. The memorial honours the contributions that the trained dentist Hart, nicknamed the ‘Flying Dentist,’ made to aviation in Australia. \n	William Ewart ‘Billy’ Hart, was not only the first man to fly cross-country when he landed his plane in Parramatta Park back in 1911, he was also the first Australian to hold a Pilot Licence and also the first Australian to crash a plane! \n\nIn the lead up to this historic flight from Penrith, Hart had purchased the Box Kite aircraft from Joseph Hammond who was touring Australia as a demonstration pilot. Hart received a few lessons from Hammond’s mechanic and it appears that he didn’t actually attain a licence until after the event, in December.\n\nHart, who apart from a couple of rudimentary lessons, was a self-taught pilot.  He purportedly crashed almost weekly in preparing for his cross-country flights.  Little is written about Hart’s wife, Thelma Clare, but she must have been nearly as courageous as her husband.\n\nCertainly, it seems the Hart’s were a plucky bunch.  It was Billy’s brother Jack, who accompanied him on that first flight, on that bright November morning, when the biplane, fitted with a beating 37-horsepower engine, soared 3,000 feet towards the clouds.\n\nThe seat was placed at the front of the plane, so there was no protection from the weather and the fabric wings were covered in sago, a starch used in puddings, which tightened the material as it dried.  Jack was reportedly so terrified by the experience that he never flew again.\n \nAll that remains today of Hart’s historic achievements is an inscription on a stone memorial placed in a park. For our tech-savvy, frequent-flying generation, it’s difficult to imagine the sheer ingenuity, skill and nerve to accomplish such pioneering triumphs.  \n\nSo why not make a sago pudding, pack up a picnic and head to Hart’s Memorial, where you can lay back and look up at the sky and imagine Billy flying overhead.  If you listen carefully, you may even hear him calling ‘Here’s for Parramatta.’\n	“For our tech-savvy, frequent-flying generation, it’s difficult to imagine the sheer ingenuity, skill and nerve to accomplish such pioneering triumphs.”	1943-01-01	\N
7	The House that Hodges Built	Said to be oldest existing example of an early colonial two-storey townhouse, this gracious Georgian building betrays nothing of her less than dignified past with her connections to gambling, drinking and petty crime. However, a long association with the medical profession has fully restored her dignity.\n	\nBrislington was built for the ex-convict and publican, John Hodges, between 1819 and 1821. A “colourful identity”, Hodges arrived in the colony as a convict. He made a valiant effort to escape the penal settlement by sea but was recaptured in the Timor Sea, transferred to another ship and returned to Port Jackson. Having served his time he received his full pardon in 1814.\n \nHodges had been selling sly grog in the colony. A gambler, Hodges’ luck changed for the better one evening when he won £1000 in gold in a card game at the Woolpack Inn. His winning card had been the eight of Diamonds. Now with financial backing, Hodges sought permission to build his own legitimate inn. The townhouse was constructed as a condition of Hodges’ application to Governor Macquarie for a Liquor License. \n\nTo commemorate his extraordinary good fortune and his winning card, Hodges had the convict labourers incorporate a diamond pattern into the rear wall of the house in darker brick. The house is thought to have been used as the Anchor & Hope Inn.\n\nUnfortunately, Hodges luck changed again when he was found guilty of stealing a large stone from the Government Quarry to build his kitchen fireplace. His conviction obliged him to sell his home and he placed a forced sale advertisement in the Sydney Gazette on 14 April 1825, stating, \n \t\n“The house is newly built...eligible for business...and secured by a perpetual grant”\n\n\nHaving had various owners, the house was purchased by Dr. Walter Brown in 1857. Brown named the home “Brislington” after his hometown in Bristol, England. Three generations of Doctors Brown resided and practiced medicine from the property until 1952.\n\n\nSince the 1850s it has been associated with the medical profession serving as a doctors residence, medical practice, as part of the Parramatta District Hospital, a nurses home and today as The Medical and Nursing Museum.	“The house is newly built...eligible for business...and secured by a perpetual grant”	1819-01-01	1821-01-01
8	 Unwrapping the Boer War Memorial	The opening remarks at the unveiling of the Boer War Memorial referred to the strong opposition shown by ‘a certain section of political representatives,’ when the Lancers volunteered to take part in the Boer War. The memorial , a miscellany of recycled columns from the 1837 Courthouse, topped by an 1856 field gun and flanked by 2 cannons, is replete, not only with architectural layers but also social and cultural significance demanding to be unwrapped.\n	In the early twentieth century monuments were the site of shared national values and ideals which commemorated courage, patriotism and the sacrifice of war, and the erection of the Boer War Memorial at Parramatta Park, in 1904, supported this sentiment.\n\nThe memorial itself is not without symbolism. The war action was seemingly well supported in Parramatta and the grand and stately pillars of the old courthouse represented their support of the empire and the broken column stood for the ten lives broken short.\n\nThe Boer War was the first overseas military engagement in which troops representing Australia, as distinct from Britain, took part. Consequently, it is no surprise that the memorial which commemorated the actions of these troops to join the fight with the British Empire against other colonists in South Africa saw some opposition at its unveiling.\n\nDespite this opposition, largely from the anti-war leagues, protesting against the reported starvation and death in concentration camps, Australians generally supported the war. But perhaps not necessarily as a devout display of loyalism but as a means of feeding their families, as enlistment offered steady pay and work.  At the outset of the Boer War in 1899 Australia was emerging from the depression of the early 1890’s which saw the collapse of many banks. \n\nThe memorial was designed by Sir John Sulman, who was also one of the first officers to enrol in the Lancers from Parramatta despite being over the ‘prescribed age.’  Incredibly, \nSulman who was also known as the ‘Father of town planning,’ has a medal named in his honour, which is today seen as a key factor in establishing the careers of young Australian Architects.\n\nThe Boer War Memorial can be interpreted in so many ways, spend an afternoon in its company, and see what it opens up for you. \n	"At the outset of the Boer War in 1899 Australia was emerging from the depression of the early 1890’s."	1904-01-01	\N
11	 ‘How Much?’ Gross Overcharging in Colonial Architecture. 	The Bath House was designed by Colonial Architect Standish Harris in 1822, and constructed a year later for Governor Brisbane. A year after its completion, the architect responsible for the elaborate heated plunge pool, domed roof and cupola lantern, was out of a job! Harris’s claim for fees and ‘gross overcharges’, considered excessive by Chief Engineer Ovens and Governor Brisbane meant Harris’ services as an architect were ‘no longer useful.’ \n	Standish Lawrence Harris arrived in Sydney in 1822, a free settler. In the same year he was appointed as the Civil Architect to replace Francis Greenway. He was permitted a 10 per cent commission on the value of works for which he was to be engaged, plus a salary of 100 pounds per annum. \n\nHis chief project, during his brief appointment was the construction of the grand Bath House designed to imitate the Roman Baths found in England. When built, the Bath House had three entranceways, leading to an outer corridor from which views to the outside could be seen through glassed windows. \n\nFor its time, the Bath House was sophisticated, with water pumped to the Bath House through lead pipes from the nearby Parramatta River, and then down to a duck pond below. Evidently, Harris felt that the complexity of a heated plunge pool with Roman mausoleum styling and ornamental cornice warranted a reasonable compensation. Standish deemed it ‘a most commodious and useful appendage to the Government House at Parramatta.’\n\nWhist there is no actual evidence in relation to any direct criticism of the Bath House, Harris’s report and expose on the public buildings of NSW, requested by the Governor, was not well received. The report, apart from being highly critical of his predecessor Greenway’s work, was also delivered with a sizeable claim for fees.\n\nBoth Brisbane and Ovens, the Chief Engineer decided that Harris was as uncooperative as his forerunner Greenway.  Apparently neither man appreciated his views on fair rewards for convicts, and came to see him as greedy and no longer of use, he was promptly dismissed.  \n\nWho knows what happened to Harris, it seems as though he sold his land and property in the Hunter region in 1831 to clear debts, and in 1846 he was still petitioning government for a large sum of money.\n\nToday the Bath House is a shaded summer house, where you can rest up and perhaps muse over what Harris’s fate...\n	"Standish deemed it ‘a most commodious and useful appendage to the Government House at Parramatta."	1822-01-01	1823-01-01
12	Cultural Clashes and Comets!	Today, very little remain of Governor Brisbane’s observatory, except for two stone piers, which once supported the transit telescope. Whilst the piers are all that remains of the southern hemisphere’s early astronomical observations, their existence takes us back to the lives of the early astronomers. The stones lead us back to the lives of Dunlop and Rumker and the workplace politics and power play that beset, even nineteenth century employees! \n\n	\n The study of the heavens was considered as an intellectual enterprise of the greatest prestige. At the outset of settlement in Australia the name of the game was sheer survival and gazing at the southern skies and stars was seen as the domain of the privileged and wealthy.  As astronomy began to be recognised as serving a practical function such as meteorology and time-keeping, men of means such as Governor Thomas Brisbane, began establishing observatories.\n\nBrisbane enlisted the help of James Dunlop and Carl Rumker who accompanied him to NSW.  The team of astronomers worked together to calculate and prepare for the appearance of Encke’s Comet in June 1822, a star that could not be seen in Europe.  \n\nAlmost a year later Rumker suddenly left the observatory.  The story goes that as Brisbane and Dunlop both came from Scotland they had a common culture which meant Dunlop was favoured.  Even though Rumker, who was from Germany, was initially praised and financially rewarded for his observation of Encke’s Comet he felt excluded by the pair. \n\nRumker is also believed to have clashed with Brisbane, because he saw himself the professional peer of Brisbane. They are believed to have fallen out as they could not compromise or agree professionally or personally on calculations, who should be credited for the scientific work, or Brisbane’s love of shooting!  \n\nApparently the relationship between Dunlop and Rumker was also strained after Rumker was given a gift of land for recovering the comet.  All the while Governor Brisbane was criticised by the Sydney community for his preoccupation with celestial events rather than addressing the problems of the colony!\n\nVisit the ‘Transit Stones’ to learn, how even in the face of great scientific discovery, the site of the Observatory was not without its problems.\n	"Governor Brisbane was criticised by the Sydney community for his preoccupation with celestial events rather than addressing the problems of the colony."	1821-01-01	1822-01-01
9	Was Dairy Cottage actually a Dairy?	History is written and re-written every day.  New evidence is found, existing records reveal many and varied interpretations and there is always the opportunity for new discoveries. This certainly seems to be the case for the Dairy Cottage whose current interpretation is under debate.  Recent research certainly adds a new layer to the current history of the Dairy Cottage, but in no way diminishes the rich tapestry of this important place. \n	According to heritage consultant Sue Rosen’s theories put forward in her book on Government House, it is quite probable that the building that is currently represented as the Dairy Cottage in the Dairy Precinct may have actually been the Garden Precinct.\n\nRosen provides a rich and complex layering of the site, but most interesting is her theory that the Dairy was in actual fact located not on the Parramatta River as currently represented, but near the Domain Creek.  \n\nThe inquest into the death of a stockman John Holland provides fascinating evidence into the basis of her argument. In December 1817 stockmen John Holland and Edward Knight went to ‘bathe in the creek near the Government Dairy.’ Holland got out of his depth in a water hole and drowned.  The assistant surgeon testified that Holland’s body was found ‘near the Government Dairy at Parramatta.’ \n\nState Records show that Knight, who was with Holland, went to look for help at the mill and from the Government Gardener, John England, whose testimony also included the word ‘creek.’ The mill referred to in the records was located on the Domain Creek.  The river did not rate a mention in the inquest which indicates that the dairy was located near the Domain Creek rather than the Parramatta River.\n\nThis analysis of evidence suggests that the dairy was located adjacent to the Domain Creek and that it has not survived. It is quite possible that the area now identified as the ‘Dairy Precinct’ was a garden and orchard area and that the house known as ‘Dairy Cottage’ was indeed the gardener’s house, constructed in 1814 with material recycled from the 1790’s!\n\nTo confuse matters further, a dairy was constructed in the gardeners’ house in 1823.  The architectural description resembles the sunken room located in the Ranger’s Cottage which is located next to the Dairy Cottage.\n\nHead on up to the Park and see if you can figure it out...\n\n	"It is quite possible that the area now identified as the ‘Dairy Precinct’ was a garden and orchard area and that the house known as ‘Dairy Cottage’ was indeed the gardener’s house."	1797-01-01	1816-01-01
10	A second bridge for Parramatta 	It’s hard to imagine a world without bridges—so often it is that we need to span rivers, traverse ravines and straddle difficult terrain. The 1885 Gasworks Bridge provided a long-awaited second crossing of Parramatta River, connecting the thriving city with the northern suburbs and beyond.\n	Called the Gasworks Bridge because of its proximity to the coal-fired gas factory—the city's well-loved 19th-century symbol of modernity. The Gasworks had been lighting the streets, shops, churches and public buildings of Parramatta since 1873, and along with other important industries was positioned by the river for easy access to coal-laden barges. \n\nEast and west of the Gasworks, mills for flour and wool were operating, and the riverfront was busy with boatsheds and inns supporting the fledgling industrial estates. Despite this, getting across the river remained difficult.\n\nBut bridge building was not to be taken lightly. From the colonial days, the need to conquer Australia's unpredictable waterways had been a constant challenge. Sandstone bridges, though popular, were slow to build, and a better solution had long been sought. \n\nJohn A McDonald, the Department of Public Works Bridge Engineer, had championed a timber-trussed bridge that had systematically been rolled out in regional towns where they could be constructed quickly from selected local timbers. He pioneered the testing of timbers to determine their strength for the purpose using a machine called the Greenwood and Batley Testing Machine located at the Sydney University School of Civil Engineering.  \n\nBut the crossing of the river at the Gasworks required a much longer span than the timber-truss bridge could offer. It demanded a more prodigious solution; one that would accommodate the future, and heavier road loads. It needed to satisfy increasing public demand for a bridge and supplement Lennox Bridge located further upstream at Church Street.\n\nThe Gasworks Bridge, also known as Newlands Bridge after the Gasworks’ engineer, John Newlands Wark, is one of 32 iron-lattice bridges built between 1870 and 1893 across the state. It has three 31-metre sections, spanning 110 metres in total. \n\nDesigned by John McDonald and his Public Works colleagues, the bridge was custom-made in England and shipped to Australia. The wrought iron components were rolled and formed into bars and strips. These pieces were welded together to create the iron-lattice trusses characteristic of its type. Arriving from England in sections, the components were bolted and welded and mounted on the buttressed sandstone piers. Relatively speedy to build, iron-lattice bridges cost approximately $9000 per metre compared to the $1500 per metre timber-truss system.\n\nWhile the Gasworks Bridge remains, the factory has long gone. However, remnants of its foundations and a number of wooden pier footings can be seen in Queens Wharf Reserve. Several commemorative sandstone blocks from the factory site are on public display at the Parramatta Heritage and Visitors Centre.\n	"Designed by John McDonald and his Public Works colleagues, the bridge was custom-made in England and shipped to Australia."	1885-01-01	\N
15	 Olympic swimmers get fresh in Parramatta Park	In 1914 Little Coogee, the beach swimming area in Parramatta Park, hosted the Olympic Carnival. The Stockholm Olympics, held two years earlier, saw efforts hampered because the Australian Olympians had been trained in salt water and not the fresh water in which they had to compete.  Little Coogee provided the ideal training conditions to protect the gold in the next Olympics – fresh water!\n	It may seem incredible today to think that Olympic swimming carnivals were held in the Parramatta River, given its current somewhat polluted state.  Nevertheless, Little Coogee became a popular, if not unofficial bathing and picnic spot from as early as the 1890’s.\n\n The beach area of Little Coogee takes its name, from when members of the Coogee Life Saving Club visited for a lifesaving and resuscitation exhibition in 1912. That same year also saw the sport of swimming enter a new phase as Sydney’s ‘lady’ swimmers fought and won the right to compete at the Stockholm Olympic Games.\n\nAs much as swimming in the river seems unbelievable today, so does the idea that women were not permitted to swim in front of men. Deemed unladylike to both compete and immoral to be seen in a swimsuit in the presence of men, competitive swimming was simply not considered acceptable for women. \n\nIt was two Sydney women, Fanny Durack and Mina Wylie who overcame convention, and at their own expense, competed in the 1912 games, and won gold and silver for Australia, while the men secured only one gold in the relay. \n\nAs the international competition from Germany, America and Britain began to heat up, so did the pressure to train and get ready for Berlin and this is how the Carnival came to be at Little Coogee.  If the competition was in fresh water, then the preparation must be too.\n\n7000 people watched the day’s events.  With no marked off lanes, no ropes and not even able to see the bottom, the competitors swam remarkably, with few incidents.  The newspapers all reported on the overwhelming success of the day. Whilst the Park had been flooded in the lead up to the event, leaving the river with a muddy hue, Parramatta Park, ‘never greatly prized,’ was touted as finally serving a purpose.  \n\nTalk a walk to Little Coogee, close your eyes and travel back in time to Saturday April 4th 1914, if you listen carefully you can almost hear the crowds cheering.	"As much as swimming in the river seems unbelievable today, so does the idea that women were not permitted to swim in front of men."	1817-01-01	\N
20	 Sanity and Shinto Gardening for good health	The beautiful Wisteria House Gardens and the grounds of the former Parramatta Hospital for the Insane still flourish with trees and flowering vines planted over one hundred years ago. They are evidence of a very modern approach to health and well-being where it was felt that the “agitation” of the insane may be calmed by eating fresh produce grown on site, spending time in the beautiful surrounds and participating in work and gentle outdoor exercise.\n	Wisteria House, also known as Glengarriff Cottage, was built in 1906-7 and designed by the prodigious Government Architect, Colonel Walter Liberty Vernon, in the “arts and crafts” Federation style. \n\nThe cottage was built as the official residence for the Medical Superintendent, Dr. William Cotter Williamson. Williamson had come to the hospital in 1883 as an Assistant Medical Superintendent. During the 1880s he was instrumental in the redesigning of the grounds and the landscaping of the site of the former “female factory”.\n\nWilliamson believed that the patients would benefit enormously from the gardens and that that they should be an integral part of effective patient care and therapy. To build the gardens, Williamson engaged the more able bodied patients, commenting that they were privileged to work but never forced to do it.\n\nIn 1907, Williamson accompanied his daughters, Nora and Nightingale, on a musical tour of Japan. Nora became a highly accomplished violinist, touring the world to great acclaim. Indeed, Williamson appreciated the positive effects of music and diversions for his patients, organizing concerts and picnics to alleviate “the gloom which is a natural concomitant of ...chronic insanity”.\n\nThe wisteria after which the Gardens are named (originally “wistaria”) was propagated from cuttings that Dr. Williamson brought back from this visit to \nJapan. The Gardens were initially designed as a “Romantic arcadia”, a kind of idyllic, harmonious space. Another Japanese element was added to the gardens in the Tori (sic) gate folly.  A torii gate typically stands at the entrance of a Shinto shrine and represents the division between the physical and spiritual realms. Perhaps Williamson hoped that his gardens might offer a similarly otherworldly experience of calm and serenity.\n\nSince 1929 the Wisteria Gardens, that include the original surviving wisteria vines, prunus trees and English elms, have been opened to the public every September.\n	"To build the gardens, Williamson engaged the more able bodied patients, commenting that they were privileged to work but never forced to do it."	1906-01-01	2001-07-01
23	House and garden on the hill: another Parramatta dress circle property 	Named by the second occupant of the property, Penelope Lucas, former governess to John Macarthur’s daughters, Hambledon Cottage is more than the residence of an ageing nanny. 	Located on relatively high ground, to the rear of the Parramatta sandbank on the richest of relatively poor soil, the property was originally part of the 100-acre land grant made to John Macarthur in 1793. Nestled on the hill between Experiment Farm to the west and Elizabeth Farm to the east, Hambledon Cottage was built between 1821 and 1824 to provide additional accommodation for Elizabeth Farm.\n\nMany colonials prized the high ground: it attracted cooling breezes, provided views, and was unlikely to flood. Land grants like these on prime real estate have earned the title of 'the dress circle' as they enabled the Parramatta elite—the nation’s early pastoralists and entrepreneurs—to securely build colonial enterprises and amass personal wealth. \n\nThe original cottage was designed by would-be-colonial architect Henry Kitchen, who arrived in Sydney in 1816 to find himself forever playing second fiddle to convict architect Francis Greenway. Before an untimely death, Kitchen found favour with Macarthur and was employed on several of his building projects, including Elizabeth Farm and Camden Park. \n\nBuilt of rendered sandstock brick in Colonial Georgian style, the joinery is of Australian cedar and is an excellent example of fine Georgian detailing. Some of the internal ceilings and walls are of lath and plaster and one bedroom retains its original ironbark floor. \n\nArchdeacon Thomas Hobbes Scott, a friend of the Macarthur's, was first to reside in the cottage in 1825, building the adjacent coach house and stables in 1826.\n\n1827 saw Scott move out and Penelope Lucas, governess to Elizabeth, Mary and Emmeline Macarthur, move in. Residing there until her death in 1836, a memorial to Lucas commemorating her activities within the church and community is displayed in St. John's Cathedral. \n\nThe enclosed garden is partly attributed to Scott and subsequently Lucas, who were both keen gardeners. Defined by a towering Bunya Pine and featuring Clivia, Wisteria, Nandina, olives, a Spanish Oak tree, the garden design and plantings illustrate the importance of the ‘home and garden package’ to colonial sentiment. Local and exotic specimens feature, along with plants Macarthur brought with him on board the "Lord Eldon" in 1817.\n\nFrom 1839-1847, Dr Matthew Anderson occupied the Cottage while acting as the Macarthur family physician. Anderson had held office as Assistant Colonial Surgeon and Surgeon at Parramatta Hospital and the Female Factory and Orphan School and was close friends with the Macarthurs. \n\nCalled 'Macarthur's Farm', the property was divided in 1883 and bought by Francis John Wickham for 1100 pounds who lived there until he died in 1892. Renaming it ‘Firholme’ he added a new entrance at Hassall Street with stone pillars and wrought iron gates bringing the property into the 20th century.\n\nPassed from owner to owner in the early part of the century, Hambledon Cottage was secured for posterity in 1950 when the Whitehall Pharmaceutical Company donated it and the northern grounds to Parramatta City Council. In 1961, the Council leased it to Parramatta and District Historical Society for use as a house museum. They have recently celebrated the museum’s 50th year of operation.	"Called 'Macarthur's Farm', the property was divided in 1883 and bought by Francis John Wickham for 1100 pounds who lived there until he died in 1892."	1821-01-01	1825-01-01
13	First stumbling blocks for Irish Australia	Catholicism in Australia had a shaky start. Just as the English were setting up shop in Sydney, they were struggling to control uprisings in other colonised lands. The 1798 Battle of Vinegar Hill in Ireland, a particularly bloody rebellion, was fought out between Irish rebels and 15,000 English soldiers. In its aftermath, more than 400 Catholic and passionately Irish rebels involved in the Battle were transported to NSW. \n	Things in Sydney and Parramatta were already tense. Food shortages threatened. Building was proving a hard slog. And converting the heathens to Anglicanism was not going well; in preference the convicts had turned to rabble-rousing with rum. So in a moment of conciliation towards the colony’s already restless Catholic population, Governor King allowed Father James Dixon—himself one of the transported rebels—to conduct the first Mass in Parramatta in 1803.\n\nIt was a decision soon regretted. Far from being appeased by the Governor’s concession, the Irish continued their political campaign against the British. They banded together and in 1804 mounted a copy-cat Vinegar Hill rebellion in Castle Hill. Nearly 300 Irish convicts gathered on the outskirts of Parramatta with a bold plan to seize control of Sydney and Parramatta, determined to return to Ireland and continue the fight against British injustices. \n\nShouting “Death or Liberty” the convicts outnumbered the Redcoats 10:1. Their leader Philip Cunningham met with Major Johnson, who suggested bringing in Father Dixon to calm things down. Cunningham retorted "Death or Liberty, and a ship to take us home" and was promptly shot. The rebels bolted and after a long night eventually rounded up and harshly punished.\n\nThe home-grown Battle of Vinegar Hill became one of the several reasons not to condone Mass nor authorise the construction of Catholic churches until the 1820s when the first official Catholic Chaplains arrived in the colony.\n\nSo it wasn’t until 1836 that the foundation stone for St Patrick’s was finally laid down providing a bona fide place of Catholic worship in Parramatta. The Church, located across the river from the Anglican St John’s and close to the Female Factory , was said to be a smaller version of St Mary’s in Sydney.\n\nOnce mover and shaker Bishop Bede Polding arrived in Sydney, things finally got on a roll and in a short time 13 Catholic primary schools were in operation, all with government support. 1854 saw the old church replaced, and later in 1904 the presbytery, Murphys House, named after assistant priest Father Peter Murphy, was built. \n\nToday, St Patrick's is both a modern Cathedral occupying its original 1820s site and a reminder of Irish struggles for independence here and abroad.\n	"Cunningham retorted "Death or Liberty, and a ship to take us home" and was promptly shot. The rebels bolted and after a long night eventually rounded up and harshly punished."	1824-01-01	1972-01-01
14	 Great Escapes	Constructed between 1835 and 1842 and finally closed in 2011, Parramatta Gaol is Australia’s oldest surviving correctional centre.  With its high perimeter fence topped with razor wire, solid sandstone walls and heavy steel gates, the dingy abandoned cells are the stuff of nightmares and have been featured in the Channel Nine crime series Underbelly. By the time of its closure it was infested with rats and the ancient plumbing was woefully inadequate. Throughout its history there have been many daring attempts to escape.\n	In 1937 a group of four prisoners attempted to break free from Parramatta Gaol with a homemade skeleton key that they had fashioned in the prison workshop. Unfortunately the key, which was made from a soft metal, jammed in the fourth door. Three of the escapees were then caught in the prison yard and two wardens were suspended.\n\nIn 1953 four dangerous inmates “borrowed” a ladder from inside the prison and tried to scale the outer wall. Only one prisoner, the notorious gunman Antonio Martini, managed to climb over the wall. Martini avoided a hail of warden’s bullets when he jumped the 35 feet to freedom but broke his ankle on landing. He was recaptured in the grounds of the adjoining mental hospital where he was loaded into a wheelbarrow and returned to the gaol. \n\nOne of Parramatta Gaol’s “celebrity” inmates was the infamous bank robber and “Escapologist” Darcy Dugan. A career criminal, Darcy “Houdini” Dugan escaped from custody six times. In 1946 he escaped using a kitchen knife to cut a hole in the roof of a prison tram whilst being escorted to court in Sydney. On another occasion in 1949, Dugan and his accomplice Cecil Meares brazenly escaped from Central Police Station using a hacksaw. His briefest period of incarceration was just 25 minutes spent in Long Bay before he tore through the ceiling, climbed onto a roof and jumped over the prison wall in plain sight.  \n\nIn 1958, whilst detained at Her Majesty’s pleasure at Parramatta Gaol, Dugan sparked a nation-wide man hunt when he was found missing at the midday roll-call. Police and prison officials suspected that Dugan had escaped in a laundry van but he was later found hiding under the floorboards in an outbuilding. Authorities promptly transferred him to solitary confinement at Long Bay.\n\nOne of the more unusual gaol-breaks was reported in the SMH of 1926 when former prisoner Frederick Jacob Anthes attempted to break back in to Parramatta Gaol to retrieve some songs he had written whilst inside. They were found in a pickle bottle buried in the prison garden.	"His briefest period of incarceration was just 25 minutes spent in Long Bay before he tore through the ceiling, climbed onto a roof and jumped over the prison wall in plain sight."	1835-01-01	1842-01-01
16	The strange allure of an orphanage.	Orphanages are for children without parents, right?\nWrong. In Sydney’s first female orphanage which opened in 1818 in Parramatta, 80% of the girls had one or both parents alive and in the colony.\n	By the early 1800s hundreds of children were in need of government care as poverty and hardship bit hard. The Female Orphan School located beside Parramatta River at Rydalmere, offered destitute mothers, single mothers and widowed fathers a place where their offspring, wanted or unwanted, would be fed, clothed, and taught to read and write. \n\nRecords indicate that parents and guardians were relatively keen to have the state look after their offspring, no doubt recognising their children’s dire futures should the school not welcome them into the fold.\n\nGaining entry to the Female Orphan School wasn’t always easy: demand outweighed supply, so one had to demonstrate a strong case for admittance.\n\nThe applications to the school are telling. In 1829 Elizabeth Griffiths, mother Margaret and Esther, wrote to the Orphanage Council stating: “That the father of these two children is now in Sydney jail under the awful sentence of death and your petitioner is a poor woman and not in a condition to provide maintenance and proper education for the above mentioned children.”\n\nOne Peter Cooke writes: “that John Lewis has two children now under his charge, a girl aged 10 and a boy aged six years to provide for, but which are principally supported by the voluntary donation of charitable people, their mother Mary Lewis died a few days after childbirth. John Lewis aged 75 has reared the child by hand-feeding since the mothers death in June 1831.” Cooke, whose relationship to the Lewis family is unknown, requested that young Charlotte be admitted to the school where she no doubt cried for want of love and comfort, and the lack of her brother’s company. \n\nWhile getting within the gates of the orphanage may have been hard, getting out again was even harder. Applications in writing were required along with evidence of the ability to provide for, educate and protect the child from moral danger. \n\nNot all children enrolled in the school went there voluntarily. Women from the Female Factory had their children placed in the orphan school once they were three years old, and in some cases were never reunited with their mothers. Aboriginal girls were also enrolled after the closure of the Native Institute.	"While getting within the gates of the orphanage may have been hard, getting out again was even harder."	1813-01-01	1940-01-01
17	The Stargazer, the Pure Merinos and the Emancipists: The great Emancipist Banquet of 1825	The Woolpack Hotel is one of the oldest pubs in Australia’s history. As one of the original watering holes welcoming all “classes” of colonial society, its patrons included wealthy pastoralists, clergy, military officers, free settlers and pardoned convicts alike. Their coexistence was not always civil and the Woolpack Hotel marks the site of one of the more acrimonious incidents highlighting the antagonism between those who came to the colony freely and those who were sent as punishment.	In December 1825, the Woolpack Hotel hosted the infamous Emancipist Banquet to farewell the retiring governor, Governor Brisbane. \n\nOriginal proprietor Andrew Nash had named the hotel “Woolpack” in recognition of the area’s significance in establishing Australia’s wool industry.  Prominent citizens and woolgrowers including John McArthur and Reverend Samuel Marsden regularly met at the inn to discuss agriculture and commerce.\n\nAs free-settlers with no penal history, they regarded themselves as morally and socially superior to those of “dubious” character who had arrived in the colony as convicts even after the prisoners had been pardoned. For their prejudice, they became known variously as the ‘Exclusionists’, ‘Exclusivists’, the ‘Aristocrats’ and the ‘Pure Merinos’.\n\nGovernor Brisbane saw little distinction between the emancipists and the free-settlers. As an advocate for the emancipists, he frequently raised the ire of the free-settlers. Privately, they derided his fanciful passion for amateur astronomy and referred to him as the Stargazer. However, they were also keen to maintain their association with a Vice-Regal representative and in October of 1925, they issued an invitation to the Governor to attend a farewell dinner in his honour at the Woolpack Hotel.\n\nThe emancipists also wanted to farewell the Governor and they too issued him with an invitation. Not wishing to attend two farewell events, Governor Brisbane proposed that the two dinners be combined and suggested to the Exclusivists that they include six prominent members of the Emancipist group.  Outraged, the Exclusivists, including McArthur and Marsden, promptly withdrew their invitation and cancelled the dinner. \n\nIn December, Governor Brisbane attended the Emancipist Banquet at the Woolpack, resplendent in his royal blue and gold attire, entering the premises to splendid fanfare from the military band. \n\nIronically, the second location of the Woolpack Hotel had originally been the site of the Reverend Marsden’s first Church.	"Governor Brisbane saw little distinction between the emancipists and the free-settlers. As an advocate for the emancipists, he frequently raised the ire of the free-settlers."	1820-01-01	1889-01-01
18	Bring on the horses	Although the word ‘lancer’ is now mostly heard in relation to a car, its association with those going into battle on horseback and the long handled javelin as their weapon of choice, goes back to medieval times. While Australia’s Lancers no longer use horses or wield the heavy lance, they do have a long and continuing history. Based in Parramatta, they have made the colonial military barracks their home.	\nAs was so often the case with the first colonial buildings, the c1790 military barracks basically fell down. Reported as being riddled with damp, and collapse imminent, in 1818, Governor Macquarie gave orders for the construction of a new barracks carriage loop and parade ground to begin. These new premises were known as the Military Barracks and were to be the eventual home of the Lancers.\n\nThe barracks saw various British regiments reside there until the 1850s when, with the convict era over, troops were withdrawn and allowed to go home. Then, for the next 40 years or so, and still without a horse in sight, government offices and the police occupied the site. \n\nIt wasn’t until January 1885 when the Sydney Light Horse Volunteers were formed that the reign of the Lancers begins. The east wing building was demolished to provide space for the horse training ground, and the barracks become the hub from which the Lancers trained to fight in the Boer War. It was here they gained the first of their 31 battle honours, collecting still others at the WWI and WW2.\n\nMuch of this success can be attributed to ‘Fighting Charlie’ Cox. Having earned his stripes in England where Charles Frederick Cox had captained a Lancer attachment, when war broke out in South Africa in 1899, Cox—plumed with emu feather in his hat— readily volunteered his regiment.\n\nDespite reportedly being a vain and forceful man, history has regaled him well: “a man of the sword and the warhorse, of the night march and the attack at dawn …”. Cox’s inspired leadership of the 1st and 2nd Light Horse Brigades continued into WWI where they saw extensive action in Gallipoli, Egypt, Palestine, and Syria.\n\nFighting Charlie’s personal photo albums and diaries are drawcards of the 6000 strong object collection held on site at Linden House Museum, one of the several buildings at Lancers Barracks.\n	"Despite reportedly being a vain and forceful man, history has regaled him well: “a man of the sword and the warhorse, of the night march and the attack at dawn …” "	1820-01-01	\N
19	Pomp, Power and Profanity in the Park	Parramatta Park has been at the centre of command and ceremony since it was cleared by 100 convicts in 1790 for the first Governor Philip. But alongside the pomp and power the Park’s ‘Speakers Corner,’ was also the scene of profanity!  In 1871, Welsh-born William Lorando Jones’, ‘wickedly profane and evil’ voice landed him in court, as the last person to be prosecuted for blasphemy in NSW.	During the late nineteenth century Parramatta Park was a popular recreation ground for planned events, such as Sunday school picnics, gala days and carnivals. It was also a haven for the homeless and unplanned events that presented both the Rangers and Trustees with their fare share of ‘unseemly scenes.’  \n\nImpromptu soap box orators often bemused the crowds at the pavilion near the Rose Hill bowling greens, on topics such as the consumption of alcohol and religion, and it was the latter that landed the respectable Mr Jones in hot water.\n\n Jones was a professional photographer, architect, lecturer and inventor and was employed as a sculptor for the chief Justice of NSW, Sir James Martin, for his residence 'Clarens' at Rushcutters Bay.\n\nFrom his platform in Parramatta Park, Mr. Jones, a member of the Sydney Secular Society said that the Old Testament Bible, was not fit to be read by young ladies. He quoted the Bible chapter and verse to prove his point to the audience of some 200 people one of whom was the aspiring young politician, Ninian Melville, Junior who took Mr. Jones to court. \n\nThe case created a great deal of interest and the moment the doors to the court opened all spaces were filled. Jones was charged with ‘being a wicked and evil disposed person, disregarding the laws and religion of the colony, and wickedly and profanely devising and intending to bring the Christian religion into disbelief and contempt.’ \n\nJones was found guilty and the Judge remarked that he would make an example of Jones to prevent a repetition of such an offence, and sentenced him to two years imprisonment in Darlinghurst Gaol and a fine of 100 pounds.\nA public outcry over the sentence, including a petition of over 2000 signatures, resulted in the release of Mr. Jones four weeks later. \n\nTake a visit to the spot where Jones delivered his blasphemous speech.	"The case created a great deal of interest and the moment the doors to the court opened all spaces were filled."	1789-01-01	\N
21	Third oldest stone bridge in NSW	It was with a stroke of luck that Major Thomas Mitchell, the Surveyor-General of NSW saw recent emigrant and stonemason David Lennox toiling away on a wall in Sydney with pick and chisel in hand. Forever on the lookout for experienced tradesmen to take on the construction of the much-needed network of roads, bridges, and drains, Mitchell had Lennox appointed as NSW Superintendent of Bridges for the Colony of NSW. \n	And it wasn’t a moment too soon. The river at Parramatta had been in need of a decent bridge for some time. The original footbridge near Pitt Street had washed away in a flood in 1785. Replaced in 1802 with a wooden bridge further downstream at Church Street, by the 1830s Governor Bourke was itching to get something more substantial in place and instructed Lennox to build “a handsome stone bridge at Parramatta without delay”.\n\nAnd handsome it certainly is. Conspicuous in its grace and repose, the single-span stone elliptical arch bridge quietly supports the busy Church Street thoroughfare today. Built with sandstone quarried from the Female Factory and spanning 23 metres; the bridge cost the foundling colony 1797 pounds. Governor Bourke laid the foundation stone on 23 November 1836 and by 1840, the bridge was in daily use. \n\nLike much of our built environment, the bridge has been modified to meet changing demands. In 1912, the western parapet was removed to provide a cantilevered walkway, and the bridge strengthened to take the weight of trams on the Parramatta-Castle Hill line. In 1934, the bridge was again widened, this time using reinforced concrete faced with sandstone. Several two-metre sections were cut out of the balustrade to accommodate stairs down to the riverbank. In 1961, a seven-metre section was removed in the southeast corner, and a concrete slab was constructed to link the wing wall with the David Jones store entrance, paid for by the already thriving retailer. \n\nAs the man of bridges, David Lennox earned his stripes. Demonstrating engineering talent and design prowess he has his name on two other NSW bridges. The Horseshoe Bridge, commonly known as Lennox Bridge in the Blue Mountains was built in 1833 and towers nine-metres above the water level, spanned by a single six-metre arch. Conrad Martens painted the bridge in celebration of the road across the Blue Mountains and an unknown artist also sketched its construction showing Lennox working with convicts with whom he is reported to have got on well.\n\nIn 1839 at Towrang in Goulburn, Lennox busied himself with a bridge and a series of six culverts or drains to usher water under the bridge. Adjacent are the remnants of the stockade, where convicts were housed while they toiled for the colony’s future of sandstone bridges.	"As the man of bridges, David Lennox earned his stripes. Demonstrating engineering talent and design prowess he has his name on two other NSW bridges."	1836-01-01	1839-01-01
22	Oldest church site and continuous place of Christian worship in Australia	When in 1798 the Reverend Samuel Marsden held the first Christian service in a makeshift wooden hut in Parramatta, only 12 worshippers attended. Despite this understated beginning, St John’s Cathedral has been at the heart of Parramatta’s colonial history, with its cast of colourful administrators, reverends and entrepreneurs, and the push and pull between social reform and colonial expansion. \n	In 1802 Governor King officially proclaimed the first two parishes in the NSW colony—St John’s Parramatta and St Phillip’s Sydney—formally recognising the Church of England as the religious authority. His choice of location was prime and the marketplace and colonial town square, now Centennial Square, spanned out around it.\n\nSt John’s transition from makeshift hut to its 1803 official stuccoed brick building in Church Street to fully-fledged Cathedral in 2011 was a difficult one. Records indicate numerous problems over time: a collapsed vestry, a repeatedly leaking roof, unstable foundations due to drainage issues and shingles falling from the two towers paid for by Elizabeth and Lachlan Macquarie’s personal funds. \n\nToday these towers are considered the oldest remaining part of any Anglican church in Australia. The north tower houses the 1821 Thwaites and Reed of London clock, a singular reminder of the importance of synchronising the lives of convicts and parishioners alike, Like the clock at Hyde Park Barracks in Sydney, the Parramatta clock is one of the oldest functioning timepieces in Australia and still requires manual winding. \n\nBut for some, the church as a theatre for convict reform and Aboriginal education tells a more interesting story; commemorated in the Cathedral in the stained glass windows and memorial tablets.\n\nThe Reverend Samuel Marsden takes centre stage. First Rector of St John’s, senior chaplain to the colony and early resident of Parramatta, history remembers Marsden as a mean-spirited man on several counts. His reputation as a cruel magistrate proceeded him—it was common for government officials and those with important jobs to act as judiciary in the early colony—and his dislike of Macquarie’s liberation policies for convicts was public knowledge. He is said to have neglected ministry for those in the Female Factory and focused disproportionately on amassing his personal wealth. \n\nGovernor Macquarie also features. Locked in a bitter battle with Marsden, in 1814, he initiated an annual feast in the marketplace at the rear of St John’s, to promote friendly relations with the local Burramatta Aboriginal people. The celebration marked the beginnings of the Black Native Institution, Macquarie’s school for Aboriginal children. Located on church land to the northeast of St John’s the school taught reading, writing and religious study, training in manual labour for the boys and needlework for the girls. \n\nIn 1823, a large Native Institution moved to Rooty Hill and became known as the Black Town Native Institution giving rise to the modern suburb of Blacktown. \nNo longer accessed from Church Street, visitors can enter St Johns from Centennial Square. The grounds were opened to the public in 1953 and feature English Oaks, Jacarandas and a mature Norfolk Island hibiscus. Extensive church records from 1789 are kept on-site as is a 1599 Geneva Bible. Today St John's is an active church and reflects Parramatta’s rich cultural diversity and conducts services in English, Mandarin, Cantonese and Farsi.\n	"But for some, the church as a theatre for convict reform and Aboriginal education tells a more interesting story."	1802-01-01	\N
\.


--
-- Name: story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_id_seq', 23, true);


--
-- Data for Name: story_photo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY story_photo (id, story_id, photo_id) FROM stdin;
1	2	1
2	3	2
3	4	3
4	6	4
5	7	5
6	8	6
7	2	8
8	1	7
9	3	9
10	4	10
11	6	11
12	7	12
13	8	13
14	9	14
15	10	15
16	2	16
17	4	17
18	6	18
19	7	19
20	8	20
21	9	21
22	1	22
23	2	23
24	4	24
25	6	25
26	7	26
27	8	27
28	10	28
29	2	29
30	9	30
31	6	31
32	7	32
33	1	33
34	11	34
35	10	35
36	9	36
37	1	37
38	11	38
39	11	39
40	10	40
41	1	41
42	11	42
43	12	43
44	10	44
45	11	45
46	12	46
47	13	47
48	1	48
49	13	49
50	15	50
51	16	51
52	13	52
53	14	53
54	15	54
55	16	55
56	17	56
57	14	57
58	13	58
59	15	59
60	16	60
61	19	61
62	18	62
63	17	63
64	15	64
65	16	65
66	19	66
67	14	67
68	13	68
69	20	69
70	16	70
71	19	71
72	14	72
73	17	73
74	18	74
75	20	75
76	21	76
77	16	77
78	19	78
79	14	79
80	17	80
81	20	81
82	21	82
83	22	83
84	17	84
85	18	85
86	20	86
87	21	87
88	22	88
89	20	89
90	22	90
91	18	91
92	22	92
93	22	93
94	18	94
95	23	95
96	23	96
97	23	97
98	23	98
99	23	99
\.


--
-- Name: story_photo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_photo_id_seq', 99, true);


--
-- Name: story_photo_photo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_photo_photo_id_seq', 1, false);


--
-- Name: story_photo_story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_photo_story_id_seq', 1, false);


--
-- Data for Name: story_site; Type: TABLE DATA; Schema: public; Owner: -
--

COPY story_site (id, story_id, site_id) FROM stdin;
1	1	1
2	2	2
3	3	3
4	4	4
5	6	5
6	5	6
7	7	7
8	8	8
9	9	9
10	10	10
11	11	11
12	12	12
13	13	13
14	14	14
15	15	15
16	16	16
17	17	17
18	18	18
19	19	19
20	20	20
21	21	21
22	22	22
23	23	23
\.


--
-- Name: story_site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_site_id_seq', 23, true);


--
-- Name: story_site_site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_site_site_id_seq', 1, false);


--
-- Name: story_site_story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('story_site_story_id_seq', 1, false);


--
-- Data for Name: views; Type: TABLE DATA; Schema: public; Owner: -
--

COPY views (id, datetime, story_id) FROM stdin;
1	2016-08-02 15:33:30	16
2	2016-08-02 15:46:10	16
3	2016-08-02 15:47:04	16
4	2016-08-02 15:47:10	16
5	2016-08-02 15:49:43	16
6	2016-08-02 16:03:12	16
7	2016-08-02 16:08:03	16
\.


--
-- Name: views_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('views_id_seq', 7, true);


--
-- Name: views_story_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('views_story_id_seq', 1, false);


--
-- Name: favourites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favourites
    ADD CONSTRAINT favourites_pkey PRIMARY KEY (id);


--
-- Name: links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: photo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY photo
    ADD CONSTRAINT photo_pkey PRIMARY KEY (id);


--
-- Name: site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: story_photo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo
    ADD CONSTRAINT story_photo_pkey PRIMARY KEY (id);


--
-- Name: story_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story
    ADD CONSTRAINT story_pkey PRIMARY KEY (id);


--
-- Name: story_site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site
    ADD CONSTRAINT story_site_pkey PRIMARY KEY (id);


--
-- Name: views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_pkey PRIMARY KEY (id);


SET search_path = hnm, pg_catalog;

--
-- Name: _RETURN; Type: RULE; Schema: hnm; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO story_discover DO INSTEAD  SELECT DISTINCT ON (story.id) story.id,
    story.title,
    story.blurb,
    photo.photo,
    json_agg(DISTINCT (json_object('{id,name,architectural_style,heritage_categories}'::text[], ARRAY[to_char(site.heritageitemid, '9999999'::text), site.name, site.architectural_style, site.heritage_categories]))::jsonb) AS sites
   FROM ((((public.story
     LEFT JOIN public.story_photo ON ((story_photo.story_id = story.id)))
     LEFT JOIN public.photo ON ((story_photo.photo_id = photo.id)))
     LEFT JOIN public.story_site ON ((story_site.story_id = story.id)))
     LEFT JOIN public.site ON ((story_site.site_id = site.id)))
  GROUP BY story.id, site.id, photo.id;


--
-- Name: _RETURN; Type: RULE; Schema: hnm; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO story_details DO INSTEAD  SELECT story.id,
    story.title,
    story.blurb,
    story.story,
    story.quote,
    min(site.suburb) AS suburb,
    json_agg(DISTINCT photo.photo) AS photos,
    json_object('{start,end}'::text[], ARRAY[to_char((story.datestart)::timestamp with time zone, 'YYYY-MM-DD'::text), to_char((story.dateend)::timestamp with time zone, 'YYYY-MM-DD'::text)]) AS dates,
    json_agg(DISTINCT (json_object('{id,name,architectural_style,heritage_categories}'::text[], ARRAY[to_char(site.heritageitemid, '9999999'::text), site.name, site.architectural_style, site.heritage_categories]))::jsonb) AS sites,
    json_agg(DISTINCT (json_object('{lat,lng}'::text[], ARRAY[site.latitude, site.longitude]))::jsonb) AS locations,
    json_agg(DISTINCT (json_object('{url,title}'::text[], ARRAY[links.link_url, links.link_title]))::jsonb) AS links
   FROM (((((public.story
     LEFT JOIN public.story_photo ON ((story_photo.story_id = story.id)))
     LEFT JOIN public.photo ON ((story_photo.photo_id = photo.id)))
     LEFT JOIN public.links ON ((links.story_id = story.id)))
     LEFT JOIN public.story_site ON ((story_site.story_id = story.id)))
     LEFT JOIN public.site ON ((story_site.site_id = site.id)))
  GROUP BY story.id;


SET search_path = public, pg_catalog;

--
-- Name: favourites_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY favourites
    ADD CONSTRAINT favourites_story_id_fkey FOREIGN KEY (story_id) REFERENCES story(id);


--
-- Name: links_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY links
    ADD CONSTRAINT links_story_id_fkey FOREIGN KEY (story_id) REFERENCES story(id);


--
-- Name: story_photo_photo_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo
    ADD CONSTRAINT story_photo_photo_id_fkey FOREIGN KEY (photo_id) REFERENCES photo(id);


--
-- Name: story_photo_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_photo
    ADD CONSTRAINT story_photo_story_id_fkey FOREIGN KEY (story_id) REFERENCES story(id);


--
-- Name: story_site_site_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site
    ADD CONSTRAINT story_site_site_id_fkey FOREIGN KEY (site_id) REFERENCES site(id);


--
-- Name: story_site_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY story_site
    ADD CONSTRAINT story_site_story_id_fkey FOREIGN KEY (story_id) REFERENCES story(id);


--
-- Name: views_story_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY views
    ADD CONSTRAINT views_story_id_fkey FOREIGN KEY (story_id) REFERENCES story(id);


--
-- PostgreSQL database dump complete
--

