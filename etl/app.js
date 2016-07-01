"use strict";

let sheet = require("./sheet.js"),
    tx = require("./transform.js"),
    db = require("./db.js"),
    geocoder = require("./geocoder.js")


// Published Google spreadsheet key - Heritage Near Me content collection
const key = "1pl8ux06rCNenhuxOSinDieVqDM906nCCFweZNHb5uX8";

// fetch passes db.load the entries it found
sheet.fetch(key, function (rows) {
    const heritageItems = rows.map(tx.cleanupHeritageRow)
    geocoder.geocode(heritageItems, function load (err, data) {
        if (err) console.log(err);
        db.load(data)
    })
})

