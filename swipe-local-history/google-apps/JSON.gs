function convertRangeToJson(range) {
  try {
    var data = range.getValues();

    // Get the headers and loop through the data in the range and build a JSON list of data
    if (data.length > 1) {
      var json = [];
      var headers = [];
      
      // Get the headers
      for (var col = 0; col < data[0].length; col++) {
        headers[col] = data[0][col];
      }
      
      // Get the JSON
      for (var row = 1; row < data.length; row++) {
        var row_json = {};
        for (var col = 0; col < data[row].length; col++) {
            row_json[headers[col]] = data[row][col];
        }
        
        json.push(row_json);
      }
    }

    return json;
  }
  catch(err) {
    Logger.log(err);
    Browser.msgBox(err);
  }
}