var commonProperties = require('../commonProperties'),
    sound = require('../sound').sound,
    Waveform = require('../waveform'),
    Onsets = require('../onsets');

// audioTrack is responsible for drawing out the audio tracks. This is a
// container for different representations of audio (waveform and/or spectrogram)
module.exports = function(){

    var width;

    var dispatch = d3.dispatch('load');

    // gets the first non blank channel in a buffer
    function getFirstNonBlankChannel(buffer){
        var nonBlankChannels = getNonBlankChannelIndexes(buffer)
        if (nonBlankChannels.length > 0){
            return buffer.getChannelData(nonBlankChannels[0]);
        }
    }

    function getNonBlankChannelIndexes(buffer){
        var nonBlankChannels = [];
        for (var i=0;i<buffer.numberOfChannels;i++){
            var channel = buffer.getChannelData(i);
            var someNonZero = channel.some(function(value){
                return value > 0;
            });
            if (someNonZero){
                nonBlankChannels.push(i);
            }
        }
        return nonBlankChannels;
    }

    function audio(selection){

        selection.each(function(d,i){
            var sequence = audio.sequence();
            var x = sequence.x();
            var width = sequence.width();
            var div = d3.select(this);
            div.append('span').text(d.name).attr('class','trackName');
    
            var svg = div.append('svg')
                        .attr('height',128)
                        .attr('width',width);

            var src = d.audioSrc || d.src;

            sound(src, function(buffer){
                d.buffer = buffer;
                d.channel = getFirstNonBlankChannel(buffer);
                var waveform = Waveform()
                    .x(x)
                    .height(128)
                    .timeline(sequence.timeline());

                svg.datum(d).call(waveform);
                dispatch.load(d);

                var onsets = Onsets()
                    .x(x)
                    .timeline(sequence.timeline())
                    //.onsetTimes(d.onsetTimes)

                svg.datum(d).call(onsets);
            });

            var uid = prong.uid();

            sequence.on('play.audio'+uid, function(){
                var audioOut = sequence.audioOut();
                if (!audioOut) return;
                var audioContext = prong.audioContext();
                var source = audioContext.createBufferSource();
                source.buffer = d.buffer;
                source.connect(audioOut);
                source.start(sequence.currentTime() + d.startTime)
                d.source = source;
            });

            sequence.on('stop.audio'+uid, function(){
                if (d.source) d.source.stop(0);
                delete d.source;
            });
        })

        

    };

    audio.redraw = function(selection, options){
        if (options && options.addOnsets){
            selection.each(function(d,i){
                var onsets = Onsets()
                    .x(x)
                    .timeline(sequence.timeline())
                    //.onsetTimes(d.onsetTimes);

                var svg = d3.select(this).select('svg');
                svg.call(onsets);
            })
        }
    }

    /* for attaching event listeners */
    audio.on = function(type, listener){
        dispatch.on(type, listener);
        return audio;
    }

    return d3.rebind(audio, commonProperties(), 'sequence');
}

