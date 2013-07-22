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
document.onselectstart = function() { return false; };

var sound = require('./sound')

module.exports = {
    waveform : require('./waveform'),
    filmstrip : require('./filmstrip'),
    onsets : require('./onsets'),
    track : require('./track'),
    registerTrackType : require('./track/track').registerTrackType,
    fx : require('./fx'),
    comper : require('./comper'),
    sound : sound.sound,
    sounds : sound.sounds,
    sequence : require('./sequence'),
    history : require('./history'),
    noteOnset : require('./noteOnset'),
    topology : require('./topology'),
    taskFeedback : require('./taskFeedback'),
    timeline : require('./timeline'),
    history : require('./history'),
    slider : require('./slider'),
    uid : require('./uid'),
    lines : require('./lines'),
    audioContext : require('./audioContext')
}