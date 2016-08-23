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
                expect(locations[0])
                    .to.have.property("location")
                    .that.is.an("object")
                    // .that.deep.equals({foo: "bar"})
                    .that.deep.equals({latitude: 48.869384, longitude: 2.3071868})

                testDone()
            })
        })

        it("skips geocoding when lat/lng already present", function (testDone) {
            let items = [{
                address: "foo bar",
                location: { latitude: 0, longitude: 0 }
            }]

            // console.log("items:")
            // console.log(items)

            geocoder.geocode (items, function validator (err, locations) {
                if (err) {
                    console.log("geocoder error: ")
                    console.log(err)
                }

                expect(items[0])
                    .to.have.property("location")
                    .that.is.an("object")
                    .that.deep.equals({latitude: 0, longitude: 0})

                testDone()
            })
        })

        it("skips geocoding when no address given", function (testDone) {

            let items = [{
                address: "", // should be skipped if .address missing or empty
                // note: no coordinates given, but no address, so geocoding should skip w/ warning
            }]

            geocoder.geocode (items, function validator (err, locations) {
                if (err) {
                    console.log("geocoder error: ")
                    console.log(err)
                }

                expect(items[0])
                    .to.not.have.property("location")

                testDone()
            })


        })
    })
})
