"use strict"

module.exports = { geocode: geocode }

const NodeGeocoder = require("node-geocoder");
const geocoder = NodeGeocoder();
const chalk = require("chalk");
// TODO: use `winston` for logging to file / console / with colors

function geocode (heritageItems, callback) {


    const geocodePromises = heritageItems.map((item, index) => new Promise (function (resolve, reject) {

        // delay each API query long enough so we don't hit Google's 10 queries / second limit
        // a delay > 100ms between queries should do the trick (10 queries * 101ms gives  >1 second / 10 queries)
        setTimeout (() => {
            geocoder.geocode(item.address, function setLocation (err, res) {
                if (err) {
                    reject(`geocoding address "${item.address}" failed: ${err}`)
                } else {
                    item.location = {}
                    item.location.latitude = res[0].latitude
                    item.location.longitude = res[0].longitude

                    resolve(item.location)
                }


            })
        }, index * 250)

    }))

    Promise.all(geocodePromises).then(values => {
        // console.log(values)
        // console.log("foo")
        callback(null, heritageItems) // should all be geocoded now
    })
    .catch(reason => {
        // uncomment this if you need it for debugging or something.
        // console.error(chalk.red("----------------------------       ----------------------------"))
        // console.error(chalk.red("---------------------------- ERROR ----------------------------"))
        // console.error(chalk.red("----------------------------       ----------------------------"))
        // console.error(heritageItems)
        // console.error(geocodePromises)
        console.error(chalk.red("Geocoder: " + reason))
        process.exit(1)
    })
}

