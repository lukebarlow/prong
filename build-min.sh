browserify --extension=.coffee -t coffeeify ./src/main.js | node_modules/uglify-js/bin/uglifyjs > prong-min.js