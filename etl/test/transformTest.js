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

    describe("#parseLinks", () => {
        it ("transforms empty string to empty list", (done) => {
            expect(transform.parseLinks("")).to.eql([])
            done()
        })

        it ("transforms one link into an array of one link", (done) => {
            expect(transform.parseLinks("http://a.com/foo.html some words"))
                .to.eql([{url: "http://a.com/foo.html", title: "some words" }])
            done()
        })

        it ("transforms two links into an array of two links", (done) => {
            const line1 = "http://a.com/foo.html some words"
            const line2 = "http://a.com/bar.html other things"
            expect(transform.parseLinks(line1 + "\n" + line2))
                .to.eql(
                    [{url: "http://a.com/foo.html", title: "some words" },
                     {url: "http://a.com/bar.html", title: "other things"}]
                )
            done()
        })
    })
})