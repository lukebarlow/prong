var app = require('./'),
	port = 8081;

var server = app.listen(port);
app.init(server);

console.log('Prong examples running at localhost:' + port);