// add remove method to array
Array.prototype.remove = function(item){
    var index = this.indexOf(item)
    if (index != -1){
        return this.splice(index, 1)
    }
}

// a few useful methods to have on Float32Arrays
Float32Array.prototype.map = Array.prototype.map
Float32Array.prototype.slice = Float32Array.prototype.subarray
Float32Array.prototype.some = Array.prototype.some

// cancel all default selection behavior
// TODO : move this behavior inside comper

var sound = require('./sound')

module.exports = {
    // componentsdocument.onselectstart = function() { return false; };
    spectrogram : require('./components/spectrogram'),

    waveform : require('./components/waveform'),
    canvasWaveform : require('./components/canvasWaveform'),
    filmstrip : require('./components/filmstrip'),
    onsets : require('./components/onsets'),
    comper : require('./components/comper'),
    timeline : require('./components/timeline'),
    musicalTimeline : require('./components/musicalTimeline.coffee'),
    slider : require('./components/slider'),
    slider2 : require('./components/slider2'),
    pot : require('./components/pot'),
    note : require('./components/note'),
    contour : require('./components/contour'),
    lines : require('./components/lines'),
    mixer : require('./components/mixer.coffee'),
    mixPresets : require('./components/mixPresets.coffee'),
    transport : require('./components/transport'),
    
    // audio/data manipulation
    fx : require('./analysis/fx'),
    //audioMatching : require('./analysis/audioMatching'),
    //leastDifference : require('./analysis/leastDifference'),
    //noteOnset : require('./analysis/noteOnset'),
    //audioMatching : require('./analysis/audioMatching'),
    //counter : require('./analysis/counter'),
    //summer : require('./analysis/summer'),
    
    // history
    history : require('./history/history'),
    editEncoding : require('./history/editEncoding'),

    // sequencer
    sequence : require('./sequence'),
    registerTrackType : require('./track/track.coffee').registerTrackType,

    // misc
    taskFeedback : require('./taskFeedback'),
    uid : require('./uid'),
    guid : require('./guid'),
    audioContext : require('./audioContext.coffee'),
    sound : sound.sound,
    sounds : sound.sounds,
    ubiquity : require('./ubiquity/ubiquity'),
    trackName : function(d, i){
        if ('name' in d) return d.name;
        if ('src' in d){
            return d.src.slice(d.src.lastIndexOf('/')+1, d.src.lastIndexOf('.'))
                .replace('_',' ');
        }
        return d.type;
    }


}