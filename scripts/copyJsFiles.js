var fs = require('fs-extra');
// copy all .js files from the src to the lib folder
fs.copySync('src','lib',{filter: /\.js$/})