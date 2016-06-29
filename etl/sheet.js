// OEH Google Spreadsheet extractor

// exports one function, fetchEntries
// fetchEntries takes a callback which is passed these arguments:
// entries (cleaned up entries found in the google spreadsheet)
// fetchEntries takes a second argument which is the spreadsheet key
//  (a default is used otherwise)

"use strict";

module.exports.fetch = fetchEntries;

// docs: https://github.com/jsoma/tabletop
const Tabletop = require("tabletop");

// callback and key are required
function fetchEntries(callback, key = null, transformRow = null) {
    Tabletop.init({ key: key || defaultKey,
                    callback: function(data, tabletop) {
                        console.log(data);
                        // parse spreadsheet data into object
                        callback((transformRow ? data.map(transformRow) : data), () => {
                            console.log("added all data from sheet")
                        });
                    },
                    simpleSheet: true,
                    // debug: true
                });
}

