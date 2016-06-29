"use strict"

let expect = require("chai").expect,
    transform = require("../transform.js")

// it should transform data

describe("transform.js", () => {
    describe("#parsePictures", () => {
        it("transforms empty string to empty list", (done) => {
            expect(transform.parsePictures("")).to.eql([])
            done()
        })

        it("transforms one image into an array of one image", (done) => {
            expect(transform.parsePictures("http://a.com/pic.jpg")).to.eql(["http://a.com/pic.jpg"])
            done()
        })

        it("transforms two images (one per line) into an array of two images", (done) => {
            expect(transform.parsePictures("http://a.com/pic.jpg\nhttp://b.com/pic2.jpg")).to.eql(
                ["http://a.com/pic.jpg", "http://b.com/pic2.jpg"]
            )
            done()
        })
    })
})