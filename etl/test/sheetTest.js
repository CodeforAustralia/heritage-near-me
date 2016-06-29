// Verify we can fetch data from a test sheet we've set up

"use strict";

let expect = require("chai").expect,
    sheet = require("../sheet.js")

// spreadsheet should contain (and return) this data:
// [ { Name: 'Jill', Age: '28', Place: 'Paris' },
//   { Name: 'Jack', Age: '30', Place: 'NYC' } ]
// sheet looks like:
// Name   Age  Place
// ----   ---  -----
// Jill    28  Paris
// Jack    30  NYC
const gSheetKey = "1KpLLYKSkh-i4f8oZTaas7Zagn-81xuRZroPoT3fY2HI"

describe("sheet.js#fetch()", function() {
    this.timeout(5000)
    it("responds with matching records", function(done) {
      sheet.fetch(function(data, tabletop) {
        expect(data).to.have.length(2);
        expect(data[0]).to.include.keys("Name");
        expect(data[0].Name).to.eql("Jill");
        expect(data[1]).to.eql({ Name: "Jack", Age: "30", Place: "NYC" });

        done();
      }, gSheetKey);
    });
});
