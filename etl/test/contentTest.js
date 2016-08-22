// test database content
// run like: NODE_ENV=dev PGHOST=localhost PGPORT=5432 PGDATABASE=hnm mocha --grep "database content" --compilers js:babel-register

"use strict"

const expect = require("chai").expect,
    SQL = require("sql-template-strings"),
    pg = require("pg"),
    Pool = require("pg-pool"),
    url = require("url"),
    validUrl = require("valid-url"),
    chalk = require("chalk"),
    request = require("request"),
    // cache DNS to make repeated calls much faster
    // http://www.madhur.co.in/blog/2016/05/28/nodejs-dns-cache.html
    // https://github.com/nodejs/node-v0.x-archive/issues/5488
    dns = require("dns"),
    dnscache = require("dnscache")({
        "enable" : true,
        "ttl" : 300,
        "cachesize" : 1000
    })

const pool = new Pool()


function seemsLikeUrl (address) {
    // because isWebUri actually returns string URI (success) or undefined (on failure)
    return new Boolean(validUrl.isWebUri(address)).valueOf()
}

// testPhotoRow : row -> promise
function testPhotoRow (row) {

    let address = row.photo
    let isUrl = seemsLikeUrl(address)

    process.stdout.write(".");

    return new Promise (

        function (resolve, reject) {

            if (!isUrl) {
                const errorString = `🚫  Invalid URL "${address}" for site: "${row.site_name}"`
                console.log(chalk.red(`\n\t ${errorString}`))
                resolve({row: row, success: false, isUrl: isUrl})
            }
            else {
                request({ method: "HEAD", uri: address }, function (error, response, body) {
                    if (error) {
                        console.log(chalk.red(`\tFailed to get URL "${address}" for site "${row.site_name}": ` + error))
                    }
                    resolve({row: row, success: !error, isUrl: isUrl, error_details: error, status: response.statusCode })
                    // if (error) {
                    //     reject ({row: row, error: error})
                    // } else if (response.statusCode == 200) {
                    //     resolve ({row: row, success: true})
                    // }
                })
            }
        }
    )
}


describe("database content", function() {

    describe("photos collection for sites", function () {

        it("has working links for all images", function (testDone) {

            this.timeout(35000)

            // try {

                pool.connect().then(client => {
                    client.query(SQL`SELECT * FROM site_photos AS site`).then(result => {

                        let numberGoodLinks = 0, numberBadLinks = 0

                        let promises = result.rows.map(testPhotoRow);
                        Promise.all(promises).then(function resolved (results) {
                            // summarize test results and assert success
                            // console.log(results)

                            const numTests = results.length
                            let numberGoodLinks = 0, numberBadLinks = 0;
                            for (result of results) {
                                result.success ? ++numberGoodLinks : ++numberBadLinks
                            }

                            console.log(`\nFinished testing ${numTests} image links: ${numberGoodLinks} OK, ${numberBadLinks} Bad`)
                            expect(numberBadLinks).to.equal(0)
                            testDone()
                        }, function rejected (reason) {
                            console.error(reason)
                            testDone()
                        })
                    })
                })

            // } catch (err) {
            //     console.log("pool connect error: " + err)
            //     testDone(err)
            // }
        })
    })
})


