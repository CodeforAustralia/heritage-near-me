// transform: clean Heritage Near Me content collection Google Spreadsheet row

"use strict"

module.exports.cleanupHeritageRow = cleanupHeritageRow


 // string -> a valid Date, or null
function toDateOrNull (date) {
    if (date === null) { return null; } // Date(null) -> 1970, so keep as null instead

    const o = new Date(date);

    // http://stackoverflow.com/questions/1353684/detecting-an-invalid-date-date-instance-in-javascript
    if ( Object.prototype.toString.call(o) === "[object Date]" ) {
        // it is a date
        if ( isNaN( o.getTime() ) ) {  // o.valueOf() could also work
            // date is not valid
            return null;
        }
        else {
            // date is valid
            return o;
        }
    }
    else {
        // not a date
        return null;
    }
}


function cleanupHeritageRow (row) {

    // return array [start,end] where either can be null
    function parseYearsString (ys) { // ys = yearS
        console.log("years: " + ys)
        if (!ys) { return [null, null]; } // undefined or ''
        else {
            const years = ys.split("-").map(function (y) { const t = y.trim(); return t ? t : null; }); // year - year
            if (years.length < 2) { return years.map(toDateOrNull).concat(null); }
            else { return years.map(toDateOrNull) }
        }
    }

    function parsePictures (ps) { // ps = pictureS
        // input is string w/ commas, newlines like "picUrl,picUrl\npicUrl\npicUrl,picUrl"
        return ps.split(/,|\n/).map(s => s.trim());
    }


    // we can do this in carto
    // // Geocoding
    // geocoder.geocode(row['Street Address'], function ( err, data ) {
    //   // do something with data
    // });

    const years = parseYearsString(row["Year"]);
    // console.log("row is: "); console.log(row);
    return {
        // story elements
        title: row["Story Title/Tagline"],
        blurb: row["Introduction"],
        story: row["Story"],
        dateStart: years[0],
        dateEnd: years[1],
        // site elements
        heritageItemId: row["Heritage ID"],
        name: row["Heritage Item Name"],
        suburb: row["Location/Suburb"],
        address: row["Street Address"],
        // latitude / longitude: geocode location
        pictures: parsePictures(row["Images"]), // should be an array of urls
        // links: unused right now, generated based on heritage id
    };
}