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
  // close: close,
  // getInsertSiteQuery: getInsertSiteQuery,
  // getInsertStorySiteSQL: getInsertStorySiteSQL,
  // getInsertPhotoSQL: getInsertPhotoSQL,
  // testEntry: {
  //   title: "e-title",
  //   blurb: "e-blurb",
  //   story: "e-story",
  //   dateStart: "1990",
  //   dateEnd: "2000",
  //   name: "e-name",
  //   suburb: "e-suburb"
  // },
  pool: pool, // use this for queries, like: db.pool.query(SQL`SELECT * from site;`)
  end: end
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

let clientCount = 0;

pool.on("connect", () => {
  clientCount++
  console.log("db.js: new client connected to database, number now connected: " + clientCount)
});

// entry -> SQL
// returns a different query depending on if we have heritageItemId or not
function getInsertSiteQuery(entry) {
  return entry.heritageItemId ?
    SQL`
      INSERT INTO site (heritageItemId, name, address, suburb)
      VALUES (${entry.heritageItemId}, ${entry.name}, ${entry.address}, ${entry.suburb}) RETURNING id AS new_site`
    :
    SQL`
      INSERT INTO site (name, address, suburb)
      VALUES (${entry.name}, ${entry.address}, ${entry.suburb}) RETURNING id AS new_site`
}

// entry -> SQL
function getInsertStorySiteSQL (entry) {
  const q = SQL`
    WITH add_story AS (
      INSERT INTO story (title, blurb, story, dateStart, dateEnd)
      VALUES (${entry.title}, ${entry.blurb}, ${entry.story}, ${entry.dateStart}, ${entry.dateEnd})
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
    // console.log("sql: generated add site+story query: ")
    // console.log(q);
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


function populateDB (entries, postPopulateCallback) {
  for (let entry of entries) {
    pool.connect().then(client => {
      // console.log("sql: inserting story + site")
      client.query(getInsertStorySiteSQL(entry)).then(result => {
        // console.log("added story / site")
        const storyId = result.rows[0].new_story;
        const insertPromises = entry.pictures.map((picUrl) => {
          // console.log(`inserting pic w/ url: '${picUrl}' for story '${storyId}'`);
          client.query(getInsertPhotoSQL(picUrl, storyId))
        })
        return Promise.all(insertPromises)
      })
      .then(() => {
        console.log("done a story, releasing client #" + clientCount)
        client.release()
        clientCount--
        // if (clientCount == 0) {
        //   // console.log("client count now 0; closing pool")
        //   // pool.end() // bug - next time we call populateDB we need to re-open the pool...
        // }
        // console.log("calling callback after releasing client")
        // debugger
        // console.log(callback)
        postPopulateCallback()
      })
      .catch(e => {
        client.release()
        console.error("query error", e.message, e.stack)
      })
    })
  }
}

// broken
// function query (string, values, callback) {
//   pool.query(string, values, () => callback())
// }

// close the pool of connections with the database
// this can be used at the end of your application
function close () {
  pool.end()
}

function end (cb) {
  pg.on("end", cb);
  pg.end()
}