function convertRangeToCsv(range) {
  try {
    var data = range.getValues();

    // Loop through the data in the range and build a string with the CSV data
    if (data.length > 1) {
      var csv = "";
      for (var row = 0; row < data.length; row++) {
        for (var col = 0; col < data[row].length; col++) {
          if (data[row][col].toString().indexOf(",") != -1
             || data[row][col].toString().indexOf("\n") != -1) {
            data[row][col] = "\"" + data[row][col].replace("\"","\\\"") + "\"";
          }
        }

        // Join each row's columns
        // Add a carriage return to end of each row, except for the last one
        if (row < data.length-1) {
          csv += data[row].join(",") + "\r\n";
        }
        else {
          csv += data[row];
        }
      }
    }
    return csv;
  }
  catch(err) {
    Logger.log(err);
    Browser.msgBox(err);
  }
}
