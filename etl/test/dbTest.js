// test adding to database

"use strict"

let expect = require("chai").expect,
    db = require("../db.js"),
    exec = require("child_process").exec,
    SQL = require("sql-template-strings")


// it should populate data with one row of test data
describe("db.js#populate()", function() {
    // this.timeout(20000)

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
        let entriesFull = [{
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
            // latitude / longitude: geocode location
            // pics
            pictures: ["http://example.com/test.jpg"]
        }]
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

        let uniqueValue = "this-is-a-test"
        let entriesPartial = [{
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
            // latitude / longitude: geocode location
            // pics
            pictures: []
        }]

         db.load(entriesPartial, function () {

            db.pool.query(SQL`SELECT id FROM story WHERE blurb = ${uniqueValue}`, function (err, result) {
                if (err) {
                  return console.error("error running query", err)
                }

                expect(result.rows).to.have.length.above(0);

                // last test, close db
                db.end(() => testDone())

                // testDone()
            });
        });

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
        exec("psql -L db.log testdb -f test/cleantestdb.sql", function(err) {
            // exec('psql -L db.log -c "drop database testdb;"', function(err) {
            // exec("sleep 2 && psql -L db.log -a -b -e -f test/droptestdb.sql", function(err) {
                if (err !== null) {
                  console.log("exec error: " + err)
                }
            })
            next()
    }, 500)

}
