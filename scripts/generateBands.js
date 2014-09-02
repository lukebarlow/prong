// generate bands for every .wav file in a directory

var exec = require('child_process').exec,
    fs = require('fs'),
    path = require('path');


// get a directory listing of the youtube cache

var root = '/Projects/prong/public/audio';

var files = fs.readdirSync(root);
files.forEach(function(file){
    if (file.slice(-4) != '.wav') return;
    var sound = path.join(root, file),
        coarse = path.join(root, file.slice(0,-3) + 'coarse.json'),
        fine = path.join(root, file.slice(0,-3) + 'fine.json');

    console.log(sound);
    generateBands(sound, 0.1, coarse);
    generateBands(sound, 0.02, fine);
})

 function generateBands(path, interval, outPath, callback){
    var bands = exec('../bin/bands ' + path + ' ' + interval + ' > ' + outPath);
     bands.on('exit', function (code) {
        console.log('Child process exited with exit code '+code);
        if (callback) callback();
     });
 }