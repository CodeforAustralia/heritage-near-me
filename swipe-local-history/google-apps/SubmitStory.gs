function submitStories() {
  // Get the stories
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Curated Stories');
  var storiesRange = sheet.getDataRange();
  var stories = convertRangeToJson(storiesRange);
  
  Logger.log(stories.map(function(d) { return d.title; }));
  
  // Update the stories
  var response = procedure('update_stories', {stories: stories});
  var ids = JSON.parse(response).map(function(d) { return d.story_id; });
  
  Logger.log(JSON.parse(response).map(function(d) { return {id: d.story_id, title: d.title}; }));
  
  // Update the IDs
  updateIds(ids);
}

function updateIds(ids) {
  // Get the current ids
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Curated Stories');
  var idRange = sheet.getRange(2, 1, ids.length, 1); // Assuming the ID column is the first one
  
  // Update the ids
  idRange.setValues(ids.map(function(id) { return [id]; }));
}