function submitStories() {
  // Log into HNM API
  var auth = adminLogin();
  Logger.log(auth);
  
  // Get the stories
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Curated Stories');
  var storiesRange = sheet.getDataRange();
  var stories = convertRangeToJson(storiesRange);
  
  // Modify stories
  stories.forEach(function(story) {
    story.links = story.links.split('\n')
      .filter(function(s) { return s != ''; })
    .map(function(s) { return {'url': s.split(' ')}; });
    story.heritage_sites = story.site_ids.split('\n')
      .filter(function(s) { return s != ''; });
  });
  
  Logger.log(stories.map(function(d) { return d.title; }));
  
  // Update the stories
  var response = procedure('update_stories', {stories: stories}, auth);
  Logger.log(JSON.parse(response).map(function(d) { return {id: d.story_id, title: d.title}; }));
  
  // Update the IDs
  var ids = JSON.parse(response).map(function(d) { return d.story_id; });
  updateIds(ids);
  
  return ids;
}

function updateIds(ids) {
  // Get the current ids
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Curated Stories');
  var idRange = sheet.getRange(2, 1, ids.length, 1); // Assuming the ID column is the first one
  
  // Update the ids
  idRange.setValues(ids.map(function(id) { return [id]; }));
}