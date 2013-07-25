fx = require('./fx');

// a simple note onset detector, based on reading here
// http://stackoverflow.com/questions/294468/note-onset-detection
module.exports = function(channel, sampleRate, options){
    
    options = options || {};

    // defaults for the options that seem to work well
    var threshold = options.threshold || 0.15,
        compressionFactor = options.compressionFactor || 0.75,
        thinningFactor = options.thinningFactor || 500,
        noteOffRatio = options.noteOffRatio || 0.7, 
        noteOnRatio = options.noteOnRatio || 3,
        noteOffDrop = options.noteOffDrop || 0.2,
        noteOnJump = options.noteOnJump || 0.18;

    var insideNote = false,
        onsetTimes = [],
        noteOffTimes = [],
        time = function(i){return i*thinningFactor/sampleRate},  
        minOutsideNote = 1,
        maxInsideNote = 0,
        data = new Float32Array(channel); // clone the channel so we don't mess up the original

    data = data.map(Math.abs);
    //fx.normalise(data);
    fx.compression(data, compressionFactor);
    data = fx.thinOut(data, thinningFactor);

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

    return {onsets : onsetTimes, 
            noteOffs : noteOffTimes};
}