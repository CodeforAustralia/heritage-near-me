// test adding to database

"use strict"

let expect = require("chai").expect,
    db = require("../db.js"),
    exec = require("child_process").exec,
    SQL = require("sql-template-strings")
    // rewire = require('rewire')

describe("db.js", function () {

    const entry = {
        // story
        title: "test-title",
        blurb: "test-blurb",
        story: "test-story",
        dateStart: new Date("1700"),
        dateEnd: new Date("1800"),
        // site
        heritageItemId: "12345678",
        name: "test-name",
        suburb: "test-suburb",
        address: "test-address",
        location: {
            latitude: "", longitude: ""
        },
        heritage_categories: "NE, SHR",
        architectural_style: "Space Alien",
        // pics
        pictures: ["http://example.com/test.jpg\nhttp://example.com/test2.jpg"]
    }

    const bigRandomNumber = Math.floor(Math.random() * 10000)
    const uniqueValue = "test-blurb-" + bigRandomNumber
    const partialEntry = {
                // story
                title: "",
                blurb: uniqueValue,
                story: "",
                dateStart: null,
                dateEnd: null,
                // site
                heritageItemId: "",
                name: "",
                suburb: "",
                address: "",
                location: {
                    latitude: "", longitude: ""
                },
                heritage_categories: "",
                architectural_style: "",
                // pics
                pictures: []
            }

    describe("getInsertSiteQuery()", function () {
        it("generates SQL to add mock site", function () {
            const q = db.getInsertSiteQuery(entry)
            expect(q).to.include.keys("strings", "values");
            expect(q.strings[0]).to.include("INSERT INTO site");
            expect(q.values).to.include(entry.heritageItemId);
            expect(q.values).to.include(entry.suburb);
            expect(q.values).to.include(entry.address);
            expect(q.values).to.include(entry.location.latitude);
            expect(q.values).to.include(entry.location.longitude);
            expect(q.values).to.include(entry.heritage_categories);
            expect(q.values).to.include(entry.architectural_style);

        })
    })

    describe("getInsertStorySiteSQL()", function () {
        it("generates SQL to add story", function () {
            const q = db.getInsertStorySiteSQL(entry);
            // console.log(q);
            expect(q).to.include.keys("strings", "values");
            expect(q.strings[0]).to.include("INSERT INTO story");
            expect(q.values).to.include(entry.title);
            expect(q.values).to.include(entry.blurb);
            expect(q.values).to.include(entry.story);
        })


        it("generates SQL to add empty story/site", function () {
            const q = db.getInsertStorySiteSQL(partialEntry)
            expect(q).to.include.keys("strings", "values");
            expect(q.strings[0]).to.include("INSERT INTO story");
            expect(q.values).to.include(partialEntry.blurb);
        })
    })


    const anotherUniqueValue = "another-unique-blurb-" + bigRandomNumber
    let entryWithLinks = {
        blurb: anotherUniqueValue,
        links: [
            {url: "http://a.gov/b.html", title: "Link A"},
            {url: "http://b.gov/c.html", title: "Link C"}
        ],
        location: {
            latitude: "", longitude: ""
        }
    }

    describe("getInsertLinksSQL()", function () {
        // linkUrl, linkTitle, storyID
        it("generates SQL to add links", function () {
            const q = db.getInsertLinksSQL(
                entryWithLinks.links[0].url,
                entryWithLinks.links[0].title,
                42);
            // console.log(q);
            expect(q).to.include.keys("strings", "values");
            // expect(q).to.include(5)
            expect(q.strings[0]).to.include("INSERT INTO links");
            expect(q.values).to.include(entryWithLinks.links[0].url);
        })
    })


    // it should populate data with one row of test data
    describe("load()", function() {
        this.timeout(20000)

        before(function(done) {
            prepare_db(function(err) {
                if(err) {
                  console.log(err)
                }
                //do other setup stuff like launching you server etc
                done()
            })
        })

        after(function(done) {
            clean_db(function (err) {
                if (err) {
                    console.log(err)
                }
                done()
            })
        })

        it("is able to add a full entry with heritage id 12345678", function(testDone) {
            let entriesFull = [entry]
            db.load(entriesFull, function verifyAdd () {
                // verify we've added it
                // console.log("in post-load callback, going to verify we added story...")
                // db.pool.query(SQL`SELECT heritageItemId AS id FROM site WHERE heritageItemId = 12345678`, function (err, result) {

                // SELECT heritageItemId AS id FROM site WHERE heritageItemId = 12345678`,
                db.pool.query(SQL`
                    WITH s AS (
                    SELECT story_site.*,story_photo.photo_id
                    FROM story_site JOIN story_photo ON story_site.story_id = story_photo.story_id
                )
                SELECT
                    s.*,
                    story.title, story.blurb, story.story, story.datestart, story.dateend,
                    site.heritageitemid, site.name, site.suburb, site.address, site.latitude, site.longitude
                    FROM s JOIN story ON s.story_id = story.id JOIN site ON s.site_id = site.id;`, function (err, result) {

                    // WITH s AS (select story_site.*,story_photo.photo_id from story_site JOIN story_photo ON story_site.story_id = story_photo.story_id) SELECT s.*, story.title, story.blurb, story.story, story.datestart, story.dateend, site.heritageitemid, site.name, site.suburb, site.address, site.latitude, site.longitude from s JOIN story ON s.story_id = story.id JOIN site ON s.site_id = site.id;

                    if (err) {
                      return console.error("error running query", err)
                    }
                    // console.log("result ")
                    // console.log(result.rows[0])
                    expect(result.rows[0].heritageitemid).to.eql(12345678)
                    expect(result.rows[0].story).to.eql(entriesFull[0].story)
                    expect(result.rows[0].title).to.eql(entriesFull[0].title)
                    expect(result.rows[0].blurb).to.eql(entriesFull[0].blurb)
                    expect(result.rows[0].name).to.eql(entriesFull[0].name)
                    testDone()
                }).catch(e => {
                    console.error("query error", e.message, e.stack)
                })
            });
        })


        it("is able to add an empty entry", function(testDone) {

             db.load([partialEntry], function () {

                db.pool.query(SQL`SELECT id FROM story WHERE blurb = ${uniqueValue}`, function (err, result) {
                    if (err) {
                      return console.error("error running query", err)
                    }

                    expect(result.rows).to.have.length.above(0);
                    testDone();
                });
            });
        })


        it("adds links to stories", function(testDone) {

            // after insertion, "Link A" and "Link C" should exist.
            db.load([entryWithLinks], function () {
                db.pool.query(SQL`SELECT * FROM links WHERE story_id = (SELECT id FROM story WHERE blurb = ${anotherUniqueValue})`, function (err, result) {
                    if (err) {
                      return console.error("error running query", err)
                    }

                    expect(result.rows).to.have.length(2);

                    // last test, close db
                    db.end(() => testDone())
                })
            })
        })

    })

})

function prepare_db(next){
    exec("./test/createtestdb.sh", function(err) {
        if (err !== null) {
            console.log("exec error: " + err)
        }
        exec("psql -d testdb -f ../backend/heritage-near-me.sql", function(err) {
            if (err !== null) {
              console.log("exec error: " + err)
            }
            next(err)
        })
    })
}

function clean_db(next) {
    setTimeout(function () {
        console.log("cleaning test database after brief pause")
        exec("psql -L db.log -f test/cleantestdb.sql testdb", function(err) {
            if (err !== null) {
              console.log("exec error: " + err)
            }
        })
        next()
    }, 500)

}
