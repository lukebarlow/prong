var audioContext = require('./audioContext')();

module.exports = {
    sound : sound, // load a sound into a buffer
    sounds : sounds, // load multiple sounds into multiple buffers
}

// modelled on d3.csv() and d3.xhr() as a simple interface to loading sound 
// buffers.
function sound(url, callback){
    var request = new XMLHttpRequest;
    request.open('GET', url, true);
    request.responseType = 'arraybuffer';
    request.onload = function(){
        var s = request.status
        audioContext.decodeAudioData(request.response, function(buffer){
            callback(buffer)
        })
    }
    request.send(null);
}

// similar to pool.sound, but second parameter is a list of urls, and the
// callback will be called with a list of corresponding buffers when all sounds
// are loaded
function sounds(urls, callback){
    var buffers = [],
        loaded = 0;
    urls.forEach(function(url, i){
        sound(url, function(buffer){
            buffers[i] = buffer;
            loaded++;
            if (loaded >= urls.length){
                callback(buffers)
            }
        });
    });
}