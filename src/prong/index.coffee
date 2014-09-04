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

    spectrogram : require('./components/spectrogram.coffee'),
    waveform : require('./components/waveform.coffee'),
    canvasWaveform : require('./components/canvasWaveform'),
    filmstrip : require('./components/filmstrip'),
    onsets : require('./components/onsets'),
    comper : require('./components/comper.coffee'),
    timeline : require('./components/timeline'),
    musicalTimeline : require('./components/musicalTimeline.coffee'),
    slider : require('./components/slider'),
    slider2 : require('./components/slider2'),
    pot : require('./components/pot.coffee'),
    note : require('./components/note'),
    contour : require('./components/contour'),
    lines : require('./components/lines'),
    mixer : require('./components/mixer.coffee'),
    mixPresets : require('./components/mixPresets.coffee'),
    transport : require('./components/transport'),
    
    # audio/data manipulation
    fx : require('./analysis/fx'),
    
    # history
    history : require('./history/history.coffee'),
    editEncoding : require('./history/editEncoding.coffee'),

    # sequencer
    sequence : require('./sequence.coffee'),
    registerTrackType : require('./track/track.coffee').registerTrackType,

    # misc
    taskFeedback : require('./taskFeedback'),
    uid : require('./uid'),
    guid : require('./guid'),
    audioContext : require('./audioContext.coffee'),
    sound : sound.sound,
    sounds : sound.sounds,
    ubiquity : require('./ubiquity/ubiquity'),
    trackName : (d, i) ->
        if ('name' of d) then return d.name
        if ('src' of d)
            return d.src.slice(d.src.lastIndexOf('/')+1, d.src.lastIndexOf('.'))
                .replace('_',' ')
        return d.type
}