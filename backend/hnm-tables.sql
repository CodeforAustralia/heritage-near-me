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
	longitude TEXT,
	architectural_style TEXT, -- like "Early Colonial" (TODO: does this include indigenous metadata?)
	heritage_categories TEXT -- like "NE, REP, LEP, SHR"
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

