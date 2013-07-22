var commonProperties = require('../commonProperties'),
    video = require('./video'),
    audio = require('./audio');

// the default track type mappings
var trackTypeMappings = {
    'audio' : audio,
    'video' : video
}

// this component is used by the sequence to look up specific track types
// and instantiate the right components for them. You can register your
// own custom track types by calling prong.registerTrackType
module.exports = function(){
    function track(selection, options){
        var components = {};
        selection.each(function(d,i){
            var sel = d3.select(this);
            if (!components[d.type]){
                components[d.type] = trackTypeMappings[d.type]().sequence(track.sequence());
            }
            components[d.type](sel, options);
        });
    }
    return d3.rebind(track, commonProperties(), 'sequence');
}

module.exports.registerTrackType = function(type, component){
    trackTypeMappings[type] = component;
}