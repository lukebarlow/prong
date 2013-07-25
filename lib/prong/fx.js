module.exports = {
    compression : compression, // compress audio in place
    normalise : normalise, // normalise audio in place
    thinOut : thinOut, // return a thinned out copy of audio data
    bandpassFilter : bandpassFilter
}

// simple power based compression based on reading here
// http://stackoverflow.com/questions/294468/note-onset-detection
// 
// a factor less than one will apply audio compression, whereas more than 1
// will expand the dynamic range
//
// note that this modifies the data in place, so if you don't want to change
// the original audio, then make a copy first.
function compression(data, factor){
    for (var i=0;i<data.length;i++){
        var sign = data[i] > 0 ? 1 : -1;
        data[i] = sign * Math.pow(Math.abs(data[i]), factor);
    }
}

// normalises the waveform in place
function normalise(data){



    var extent = d3.extent(data),
        maxAmplitude = d3.max(extent.map(Math.abs));
        multiplier = 1 / maxAmplitude;

    for (var i=0;i<data.length;i++){
        data[i] *= multiplier;
    }
}

// this will thin out the data by taking every chunks of samples at a time
// and applying an aggregating function to them. The aggregator function is
// optional, and will default to d3.max. So, for example if thinningFactor = 4
// and aggregator = d3.max, then the return value will be an array with 1/4 the
// number of elements, each element being the maximum of a group of 4 of the
// original array.
function thinOut(data, thinningFactor, aggregator){
    if (thinningFactor == 1) return data;
    aggregator = aggregator || d3.max;
    if (typeof(aggregator) == 'string'){
        aggregator = {
            max : d3.max,
            first : function(d){return d[0]}
        }[aggregator]
    }

    var thinnedArray = [];
    for (var i=0;i<data.length;i+=thinningFactor){
        thinnedArray.push(aggregator(data.slice(i,i+thinningFactor)));
    }
    return thinnedArray;
}

// async method. Applies a band pass filter of specified frequency and Q value
// to the buffer, and calls the callback with the result
function bandpassFilter(buffer, frequency, Q, callback){
    window.OfflineAudioContext = window.OfflineAudioContext||window.webkitOfflineAudioContext;
    var context = new OfflineAudioContext(2, buffer.length, buffer.sampleRate),
        source = context.createBufferSource();
    source.buffer = buffer;

    var filter = context.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = frequency;
    filter.Q.value = Q;
    source.connect(filter);

    var gain = context.createGain();
    gain.gain.value = 0.6;
    filter.connect(gain)

    gain.connect(context.destination);
    context.startRendering();
    source.start(0);

    context.oncomplete = function(e){
        callback(e.renderedBuffer)
    }

}