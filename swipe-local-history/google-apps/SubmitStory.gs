function submitStories() {
  var headers = 'title,blurb,story\n';
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Curated Stories');
  var numStories = sheet.getLastRow();
  var storiesRange = sheet.getRange('C2:E'+numStories);
  var stories = convertRangeToCsv(storiesRange);
  var response = bulkInsert('story', headers+stories);
  Logger.log(response);
}
