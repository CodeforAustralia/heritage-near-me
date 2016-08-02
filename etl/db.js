// Postgres database loader

"use strict";

const pg = require("pg"),
      SQL = require("sql-template-strings"),
      Pool = require("pg-pool")

// create the pool and let it live 'globally' here,
// controlling access through exported methods
// https://github.com/brianc/node-pg-pool#a-note-on-instances
// const pool = new Pool({log: console.log})
const pool = new Pool()

module.exports = {
  load: populateDB,
  pool: pool, // use this for queries, like: db.pool.query(SQL`SELECT * from site;`)
  end: end,
  getInsertSiteQuery: getInsertSiteQuery,
  getInsertStorySiteSQL: getInsertStorySiteSQL,
  getInsertLinksSQL: getInsertLinksSQL,
}

// attach an error handler to the pool for when a connected, idle client
// receives an error by being disconnected, etc
// https://github.com/brianc/node-pg-pool#events
pool.on("error", function(error, client) {
  // handle this in the same way you would treat process.on('uncaughtException')
  // it is supplied the error as well as the idle client which received the error
  console.log("Unexpected error from Postgres pg-pool client. Error: ")
  console.log(error)
  console.log(client)
})

let acquireCount = 0
pool.on("acquire", function (client) {
  acquireCount++
  console.log("db.js: client acquired from pool, bringing total number of acquires to: " + acquireCount)
})

let clientCount = 0;
pool.on("connect", () => {
  clientCount++
  console.log("db.js: new client connected to database, number now connected: " + clientCount)
});

// entry -> SQL
// returns a different query depending on if we have heritageItemId or not
function getInsertSiteQuery(entry) {
  let q = entry.heritageItemId ?
    SQL`
      INSERT INTO site (heritageItemId, name, address, suburb, latitude, longitude, architectural_style, heritage_categories)
      VALUES (${entry.heritageItemId}, ${entry.name}, ${entry.address}, ${entry.suburb}, ${entry.location.latitude}, ${entry.location.longitude}, ${entry.architectural_style}, ${entry.heritage_categories}) RETURNING id AS new_site`
    :
    SQL`
      INSERT INTO site (name, address, suburb, latitude, longitude, architectural_style, heritage_categories)
      VALUES (${entry.name}, ${entry.address}, ${entry.suburb}, ${entry.location.latitude}, ${entry.location.longitude}, ${entry.architectural_style}, ${entry.heritage_categories}) RETURNING id AS new_site`
  return q
}

// entry -> SQL
function getInsertStorySiteSQL (entry) {
  const q = SQL`
    WITH add_story AS (
      INSERT INTO story (title, blurb, story, quote, dateStart, dateEnd)
      VALUES (${entry.title}, ${entry.blurb}, ${entry.story}, ${entry.quote}, ${entry.dateStart}, ${entry.dateEnd})
      RETURNING id AS new_story
      )
    , add_site AS (`
    .append(getInsertSiteQuery(entry))
    .append(SQL`
      )
    , link_story_site AS (
      INSERT INTO story_site(story_id, site_id)
      SELECT new_story, new_site
      FROM add_story, add_site
      )
    SELECT * from add_story;`)
    return q;
}

function getInsertPhotoSQL (picUrl, storyId) {
  return SQL`
  WITH add_photo AS (
    INSERT INTO photo (photo)
    VALUES (${picUrl})
    RETURNING id AS new_photo_id
    )
  , link_story_photo AS (
    INSERT INTO story_photo(story_id, photo_id)
    SELECT ${storyId}, new_photo_id
    FROM add_photo
    )
  SELECT new_photo_id AS photo_id from add_photo;`
}

function getInsertLinksSQL (linkUrl, linkTitle, storyID) {
  return SQL`
    INSERT INTO links (link_url, link_title, story_id)
    VALUES (${linkUrl}, ${linkTitle}, ${storyID})`
}

function populateDB (entries, postPopulateCallback) {
  for (let entry of entries) {
    pool.connect().then(client => {
      // console.log("sql: inserting story + site")
      client.query(getInsertStorySiteSQL(entry)).then(result => {
        // console.log("added story / site")
        const storyID = result.rows[0].new_story;
        const photos = entry.pictures || [];
        const links = entry.links || [];
        const insertPicPromises = photos.map((picUrl) => {
          // console.log(`inserting pic w/ url: '${picUrl}' for story '${storyID}'`);
          return client.query(getInsertPhotoSQL(picUrl, storyID))
        })

        const insertLinkPromises = links.map((link) => {
          return client.query(getInsertLinksSQL (link.url, link.title, storyID))
        })

        return Promise.all(insertPicPromises.concat(insertLinkPromises))
      })
      .then(() => {
        console.log("done a story, releasing client #" + clientCount)
        client.release()
        clientCount--
        if (typeof postPopulateCallback === "function") { postPopulateCallback() }
      })
      .catch(e => {
        client.release()
        console.error("query error", e.message, e.stack)
      })
    })
  }
}

// close the pool of connections with the database
// this can be used at the end of your application
function close () {
  pool.end()
}

function end (cb) {
  pg.on("end", cb);
  pg.end()
}