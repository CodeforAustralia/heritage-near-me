"use strict"

module.exports = { geocode: geocode }

const NodeGeocoder = require("node-geocoder");
const geocoder = NodeGeocoder();

function geocode (heritageItems, callback) {


    const geocodePromises = heritageItems.map((item) => new Promise (function (resolve, reject) {

        geocoder.geocode(item.address, function setLocation (err, res) {
            if (err) {
                reject(`geocoding address "${item.address}" failed: ${err}`)
            }

            item.location = {}
            item.location.latitude = res[0].latitude
            item.location.longitude = res[0].longitude

            resolve(item.location)
        })
    }))

    Promise.all(geocodePromises).then(values => {
        console.log(values)
        console.log("foo")
        callback(null, heritageItems) // should all be geocoded now
    })
    .catch(reason => {
        console.log("Geocoding failed: " + reason)
        console.log(heritageItems)
        console.log(geocodePromises)
    })
}

