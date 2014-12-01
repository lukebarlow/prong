var express = require('express'),
    app = express(),
    browserify = require('browserify-middleware'),
    ubiquity = require('./src/prong/server/ubiquity-server'),
    coffeeify = require('caching-coffeeify');

browserify.settings('extensions', ['.coffee','.js'])
browserify.settings('transform', coffeeify)

app.get('/js/prong.js', browserify('../prong/src/main.js'))
app.use(express.static(__dirname + '/public'));

module.exports = app;
app.init = function(server){
    ubiquity(server);
}
