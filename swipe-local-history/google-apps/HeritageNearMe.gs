function apiRequest(method, subUrl, headers, payload) {
  var url = 'http://heritagenear.me:8000/api/'+subUrl;
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

function procedure(subUrl, data) {
  return apiRequest('POST', 'rpc/'+subUrl, {'Content-Type': 'application/json'}, JSON.stringify(data));
}
