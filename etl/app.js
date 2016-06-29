"use strict";

let sheet = require("./sheet.js"),
    tx = require("./transform.js"),
    db = require("./db.js");

    // geocoder = require("geocoder");


// Published Google spreadsheet key - Heritage Near Me content collection
const key = "1pl8ux06rCNenhuxOSinDieVqDM906nCCFweZNHb5uX8";

// fetch passes db.load the entries it found
sheet.fetch(db.load, key, tx.cleanupHeritageRow);

// sheet.fetch((data) => console.log("" /* data */), key, tx.cleanupHeritageRow);
