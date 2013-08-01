fx = require('./fx');

// a simple note onset detector, based on reading here
// http://stackoverflow.com/questions/294468/note-onset-detection
module.exports = function(channel, sampleRate, options, callback){
    
    options = options || {};

    // defaults for the options that seem to work well
    var threshold = options.threshold || 0.15,
        compressionFactor = options.compressionFactor || 0.75,
        thinningFactor = options.thinningFactor || 500,
        noteOffRatio = options.noteOffRatio || 0.7, 
        noteOnRatio = options.noteOnRatio || 3,
        noteOffDrop = options.noteOffDrop || 0.2,
        noteOnJump = options.noteOnJump || 0.18,
        //filterFrequency = options.filterFrequency || 880,
        //filterFrequency = options.filterFrequency || 5000,
        filterFrequency = options.filterFrequency || 10000,
        filterQ = options.filterQ || 0.1;

    var insideNote = false,
        onsetTimes = [],
        noteOffTimes = [],
        time = function(i){return i*thinningFactor/sampleRate},  
        minOutsideNote = 1,
        maxInsideNote = 0;

    prong.fx.bandpassFilter(channel, sampleRate, filterFrequency, filterQ, function(data){
    //var data = new Float32Array(channel);
        // a little hack to show the effected audio in the waveform
        // var afterBandpass = new Float32Array(data);
        // fx.normalise(afterBandpass);
        // fx.compression(afterBandpass, compressionFactor);

        //equivalent to "data = data.map(Math.abs)" but much faster;
        for (var i=0;i<data.length;i++){
            if (data[i] < 0) data[i] = 0 - data[i];
        }
        
        data = fx.thinOut(data, thinningFactor);
        fx.normalise(data);
        fx.compression(data, compressionFactor);

        for (var i=0;i<data.length;i++){
            var value = data[i];
            if (insideNote){
                maxInsideNote = Math.max(maxInsideNote, value);
                if ( (value < (maxInsideNote - noteOffDrop))
                    ||
                    (value < (maxInsideNote * noteOffRatio)
                    )){
                    noteOffTimes.push(time(i));
                    insideNote = false;
                    minOutsideNote = value;
                }
            }else{
                minOutsideNote = Math.min(value, minOutsideNote);
                if (
                    (value > threshold)
                    && (
                        (value > minOutsideNote + noteOnJump)
                        || 
                        (value > minOutsideNote * noteOnRatio)
                    )
                ){
                    maxInsideNote = value;
                    insideNote = true;
                    onsetTimes.push(time(i));
                }
            }
        }
        
        // var result = {
        //     onsets : onsetTimes, 
        //     noteOffs : noteOffTimes,
        //     //channel : afterBandpass
        // }

        // return result;

        callback({
            onsets : onsetTimes, 
            noteOffs : noteOffTimes,
            //channel : afterBandpass
        })
    })    
}

module.exports.bumps = bumps;

// this synchronous method just looks for bumps in the data. It doesn't
// do any preparation or alteration of the data
function bumps(data, sampleRate, options){

    var options = options || {},
        threshold = options.threshold || 0.15,
        compressionFactor = options.compressionFactor || 0.75,
        noteOffRatio = options.noteOffRatio || 0.7, 
        noteOnRatio = options.noteOnRatio || 3,
        noteOffDrop = options.noteOffDrop || 0.2,
        noteOnJump = options.noteOnJump || 0.18;

    var insideNote = false,
        onsetTimes = [],
        noteOffTimes = [],
        time = function(i){return i/sampleRate},  
        minOutsideNote = 1,
        maxInsideNote = 0;

    var dropRate = 1;
    var dropPerIteration = 1 / sampleRate / dropRate;
    var value = 0;

    for (var i=0;i<data.length;i++){
        // the dropRate logic smooths the wave so it will not respond to
        // sudden down and up movements
        var datum = data[i];
        value = value - dropPerIteration;
        if (datum > value) value = datum;
        if (value < 0) value = 0;

        if (insideNote){
            maxInsideNote = Math.max(maxInsideNote, value);
            if ( (value < (maxInsideNote - noteOffDrop))
                ||
                (value < (maxInsideNote * noteOffRatio)
                )){
                noteOffTimes.push(time(i));
                insideNote = false;
                minOutsideNote = value;
            }
        }else{
            minOutsideNote = Math.min(value, minOutsideNote);
            if (
                (value > threshold)
                && (
                    (value > minOutsideNote + noteOnJump)
                    || 
                    (value > minOutsideNote * noteOnRatio)
                )
            ){
                maxInsideNote = value;
                insideNote = true;
                onsetTimes.push(time(i));
            }
        }
    }

    return {
        onsets : onsetTimes,
        noteOffs : noteOffTimes
    }
}
