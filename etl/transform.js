// transform: clean Heritage Near Me content collection Google Spreadsheet row

"use strict"

module.exports = {
    cleanupHeritageRow: cleanupHeritageRow,
    parsePictures: parsePictures,
    parseLinks: parseLinks
}


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

function parsePictures (ps) { // ps = pictureS
    // input is string w/ commas, newlines like "picUrl,picUrl\npicUrl\npicUrl,picUrl"
    // blank lines are excluded from results
    return ps.split(/,|\n/).map(s => s.trim()).filter((s) => s != "");
}

function head(array) {
    return array.slice(0,1)[0]
}
function tail(array) {
    return array.slice(1)
}

// String -> [ { url: String, title: String }]
// input is string like "URL a description\nURL another description"
function parseLinks (ls) { // ls = linkS
    const lines = ls.split(/\n/).map((line) => line.trim()).filter((s) => s != "");
    return lines.map((line) => {
        const words = line.split(/\s/)
        return { url: head(words), title: tail(words).join(" ") }
    })
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
        story: row["Story Body"],
        quote: row["Extract Quote"],
        dateStart: years[0],
        dateEnd: years[1],
        // site elements
        heritageItemId: row["Heritage ID"],
        name: row["Heritage Item Name"],
        suburb: row["Location/Suburb"],
        address: row["Street Address"],
        location: {},
        // latitude / longitude: geocode location
        heritage_categories: row["Heritage Categories"],
        architectural_style: row["Architectural Style"],
        links: parseLinks(row["Links & Further Reading"]),
        pictures: parsePictures(row["Images"]), // should be an array of urls
        // links: unused right now, generated based on heritage id
    };
}