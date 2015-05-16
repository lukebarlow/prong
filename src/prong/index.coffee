# add remove method to array
Array.prototype.remove = (item) ->
    index = this.indexOf(item)
    if (index != -1)
        return this.splice(index, 1)
    

# a few useful methods to have on Float32Arrays
Float32Array.prototype.map = Array.prototype.map
Float32Array.prototype.slice = Float32Array.prototype.subarray
Float32Array.prototype.some = Array.prototype.some


sound = require('./sound')

module.exports = {

    spectrogram : require('./components/spectrogram'),
    waveform : require('./components/waveform'),
    canvasWaveform : require('./components/canvasWaveform'),
    filmstrip : require('./components/filmstrip'),
    onsets : require('./components/onsets'),
    comper : require('./components/comper'),
    timeline : require('./components/timeline'),
    musicalTimeline : require('./components/musicalTimeline'),
    musicalTime : require('./musicalTime'),
    slider : require('./components/slider'),
    pot : require('./components/pot'),
    contour : require('./components/contour'),
    lines : require('./components/lines'),
    mixer : require('./components/mixer'),
    transport : require('./components/transport'),
        
    # history
    history : require('./history/history')
    omniscience : require('./omniscience')

    # sequencer
    sequence : require('./sequence'),
    registerTrackType : require('./track/track').registerTrackType,

    # misc
    uid : require('./uid'),
    guid : require('./guid'),
    audioContext : require('./audioContext'),
    sound : sound.sound,
    sounds : sound.sounds,
    trackName : require('./trackName'),

    # this is the custom build of d3 with just the features needed for prong
    d3 : require('./d3-prong-min')
}