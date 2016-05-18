sound = require('./sound')
#require('chrome-proxy')


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
    automation : require('./components/automation'),
    lines : require('./components/lines'),
    mixer : require('./components/mixer'),
    transport : require('./components/transport'),
    presetList : require('./components/presetList'),
        
    # history
    history : require('./history/history'),
    omniscience : require('omniscience')
    
    # sequencer
    sequence : require('./sequence'),
    registerTrackType : require('./track/track').registerTrackType,

    # misc
    uid : require('./uid'),
    guid : require('./guid'),
    audioContext : require('./audioContext'),
    sound : sound.sound,
    sounds : sound.sounds,

    organ : require('./organ'),
    organController : require('./components/organController')

    # this is the custom build of d3 with just the features needed for prong
    d3 : require('d3-prong')
}