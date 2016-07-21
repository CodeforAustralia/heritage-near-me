"use strict";

let expect = require("chai").expect,
    geocoder = require("../geocoder.js")

describe("geocoder.js", function () {
    describe("#geocode()", function () {

        it("geocodes an address correctly", function (testDone) {
            let items = [{
                address: "29 champs elysée paris",
            }]
            geocoder.geocode (items, function validator (err, locations) {
                // console.log("testGeocoder.js#validator...")
                if (err) {
                    console.log("geocoder error: ")
                    console.log(err)
                }
                if (locations) {
                    // console.log("locations: ")
                    // console.log(locations)
                }
                // console.log(items)
                expect(items[0])
                    .to.have.property("location")
                    .that.is.an("object")
                    // .that.deep.equals({foo: "bar"})
                    .that.deep.equals({latitude: 48.869384, longitude: 2.3071868})

                testDone()
            })
        })
    })
})
