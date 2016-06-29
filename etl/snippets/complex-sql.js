"use strict"
const SQL = require("sql-template-strings")

const entry = {
  title: "e-title",
  blurb: "e-blurb",
  story: "e-story",
  dateStart: "1990",
  dateEnd: "2000",
  name: "e-name",
  suburb: "e-suburb"
}

// return a valid Date, or null
function d (date) {
  const o = new Date(date);

  // http://stackoverflow.com/questions/1353684/detecting-an-invalid-date-date-instance-in-javascript
  if ( Object.prototype.toString.call(o) === "[object Date]" ) {
    // it is a date
    if ( isNaN( o.getTime() ) ) {  // o.valueOf() could also work
      // date is not valid
      return null;
    }
    else {
      // date is valid
      return o;
    }
  }
  else {
    // not a date
    return null;
  }
}

const q = SQL`
  WITH add_story AS (
    INSERT INTO story (title, blurb, story, dateStart, dateEnd)
    VALUES (${entry.title}, ${entry.blurb}, ${entry.story}, ${d(entry.dateStart)}, ${d(entry.dateEnd)})
    returning new_story
    )
  , add_site AS (
    INSERT INTO site (name, suburb)
    VALUES (${entry.name}, ${entry.suburb})
    RETURNING new_site
    )
  , link_story_site AS (
    INSERT INTO story_site(story_id, site_id)
    SELECT new_story, new_site
    FROM add_story, add_site
    )
  SELECT new_story AS story_id from add_story;`

const q0 = SQL`INSERT INTO story (title, blurb) VALUES (${entry.title}, ${entry.blurb}) returning new_story`
// console.log(q0);


console.log(q);
