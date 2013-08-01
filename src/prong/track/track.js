var commonProperties = require('../commonProperties'),
    video = require('./video'),
    audio = require('./audio');

// the mapping from track type strings to component constructor functions
var trackTypeMappings = {
    'audio' : audio,
    'video' : video
}

// the mapping from file endings to track type strings
var fileTypesToTrackTypes = {
    'mp3' : 'audio',
    'wav' : 'audio',
    'm4a' : 'audio',
    'mp4' : 'video',
    'ogg' : 'video' // confusing. ogg can be just audio
}


// this component is used by the sequence to look up specific track types
// and instantiate the right components for them. You can register your
// own custom track types by calling prong.registerTrackType
module.exports = function(){

    var dispatch = d3.dispatch('load');

    function track(selection, options){
        var components = {};
        selection.each(function(d,i){
            var sel = d3.select(this);
            if (!components[d.type]){
                var component = trackTypeMappings[d.type]().sequence(track.sequence());
                if (component.on){
                    component.on('load', dispatch.load) // forward the load event
                }
                components[d.type] = component;
            }
            components[d.type](sel, options);
        });
    }

    track.on = function(type, listener){
        dispatch.on(type, listener)
    }

    return d3.rebind(track, commonProperties(), 'sequence');
}

module.exports.registerTrackType = function(type, component){
    trackTypeMappings[type] = component;
}

module.exports.unpackTrackData = function(tracks){
    tracks.forEach(function(track, i){
        if (typeof(track) == 'string'){
            var fileType = track.split('.').pop(),
                trackType = fileTypesToTrackTypes[fileType];
            tracks[i] = {
                src : track,
                type : trackType
            }
        }
    })
}