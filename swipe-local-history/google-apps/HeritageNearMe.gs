function apiRequest(method, subUrl, headers, payload) {
  var url = 'http://27.33.71.166:8000/api/'+subUrl;
  var options = {
    'method': method,
    'headers': headers,
    'payload': payload,
  };
  
  Logger.log(JSON.stringify(arguments))
  var response = UrlFetchApp.fetch(url, options);
  return response;
}

function bulkInsert(subUrl, data, auth) {
  return apiRequest('POST', subUrl, authorize({'Content-Type': 'text/csv'}, auth), data);
}

function procedure(subUrl, data, auth) {
  if (auth)
    return apiRequest('POST', 'rpc/'+subUrl, authorize({'Content-Type': 'application/json'}, auth), JSON.stringify(data));
  else
    return apiRequest('POST', 'rpc/'+subUrl, {'Content-Type': 'application/json'}, JSON.stringify(data));
}

function authorize(headers, auth) {
  headers['Authorization'] = 'Bearer ' + auth.token;
  return headers;
}

function login(user, password) {
  return procedure('login', {email: user, pass: password});
}