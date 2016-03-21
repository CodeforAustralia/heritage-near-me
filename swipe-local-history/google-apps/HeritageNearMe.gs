function apiRequest(method, subUrl, headers, payload) {
  var url = 'http://27.33.71.166:8000/api/'+subUrl;
  var options = {
    'method': method,
    'headers': headers,
    'payload': payload,
  };
  
  var response = UrlFetchApp.fetch(url, options);
  return response;
}

function bulkInsert(subUrl, data) {
  return apiRequest('POST', subUrl, {'Content-Type': 'text/csv'}, data);
}
