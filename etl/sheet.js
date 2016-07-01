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
function fetchEntries(key, callback) {
    Tabletop.init({ key: key,
                    callback: function(data, tabletop) {
                        console.log(data);
                        callback(data);
                    },
                    simpleSheet: true,
                    // debug: true
                });
}

