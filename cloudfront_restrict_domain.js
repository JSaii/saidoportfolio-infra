function handler(event) {
  var request = event.request;
  var host = request.headers.host.value.toLowerCase();

  if (host !== "josephsaido.com" && host !== "www.josephsaido.com") {
    return {
      statusCode: 403,
      statusDescription: "Forbidden",
      body: "Access denied. Please use josephsaido.com.",
    };
  }

  return request;
}
