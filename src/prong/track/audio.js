var commonProperties = require('../commonProperties'),
    sound = require('../sound').sound,
    Waveform = require('../components/waveform'),
    Onsets = require('../components/onsets'),
    //Lines = require('../components/lines'),
    Note = require('../components/note');

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

    // the default sound loader
    function httpSoundLoader(loadingMessage, callback){
        var track = this;
        sound(track.src, function(buffer){
            track._buffer = buffer;
            track._channel = getFirstNonBlankChannel(track._buffer);
            callback();
        }, function(progress){
            loadingMessage.text(progress)
        });
    }

    function audio(selection){

        //console.log('APPLYING AUDIO TO SELECTION')

        selection.each(function(d,i){
            var sequence = audio.sequence(),
                x = sequence.x(),
                width = sequence.width(),
                height = d.height || sequence.trackHeight() || 128,
                div = d3.select(this);

            if (!('volume' in d)) d.volume = 1;

            div.append('div').attr('class','trackName').append('span').text(prong.trackName);
            var loadingMessage = div.append('span').attr('class','trackLoading');

            var svg = div.append('svg')
                .attr('height',height)
                .attr('width', '100%')
                .on('mouseover', function(d){
                    if (!prong._dragging){
                        d3.select(this).classed('over', true);
                        d.over = true;
                    }
                })
                .on('mouseout', function(d){
                    d3.select(this).classed('over', false);
                    d.over = false;
                })
                .each(function(d){
                    var thiz = d3.select(this);
                    d.watch('over', function(){
                        thiz.classed('over', d.over);
                    })
                });

        
            var src = d.audioSrc || d.src;

            // each track has a 'loader' method which is responsible for
            // asynchronously loading and decoding the data, and reporting
            // on progress as it goes. The default one loads from http. Once
            // the loader is complete, the track should have channel and
            // buffer properties
            if (!('_loader' in d)){
                if ('channel' in d){
                    // if we already have a channel set, set a 'do nothing' loader
                    d._loader = function(_,callback){callback()}
                }else{
                    d._loader = httpSoundLoader;
                }
            } 

            d._loader(loadingMessage, function(){
                loadingMessage.remove();
                var waveform = Waveform()
                    .x(x)
                    .height(height)
                    .verticalZoom(sequence.waveformVerticalZoom())
                    .timeline(sequence.timeline());

                svg.call(waveform);
                dispatch.load(d);

                var onsets = Onsets()
                    .x(x)
                    .timeline(sequence.timeline())

                svg.call(onsets);

                var note = Note()
                    .x(x)
                    .timeline(sequence.timeline())
                    .height(height)
                    .colour('pink')
                    .key('notes');

                svg.call(note);
            })

            var uid = prong.uid();

            sequence.on('play.audio'+uid, function(){

                var audioOut = sequence.audioOut();
                if (!audioOut || !d._buffer) return;
                var audioContext = prong.audioContext();
                var source = audioContext.createBufferSource();
                source.buffer = d._buffer;
                
                var gain = audioContext.createGain();
                var panner = audioContext.createPanner();

                function setVolume(){
                    gain.gain.value = d.volume / 100.0;
                }

                d.watch('volume', function(){
                    setVolume();
                });

                setVolume();

                function setPan(){
                    // pan numbers are between -64 and +63. We convert this
                    // into an angle in radians, and then into an x,y position
                    var angle = d.pan / 64 * Math.PI * 0.5,
                        x = Math.sin(angle) / 2,
                        y = Math.cos(angle) / 2;

                    panner.setPosition(x, y, 0);
                }

                d.watch('pan', function(){
                    setPan();
                })

                setPan();

                source.connect(gain);
                gain.connect(panner);
                panner.connect(audioOut);

                var timeOffset = sequence.currentTime() - (d.startTime || 0),
                    when = timeOffset < 0 ? audioContext.currentTime - timeOffset : 0,
                    offset = timeOffset > 0 ? timeOffset : 0;

                source.start(when, offset);
                                
                d.source = source;
                d.gain = gain;
            });

            sequence.on('stop.audio'+uid, function(){
                if (d.source){
                    d.source.stop(0)
                };
                delete d.source;
            });

            sequence.on('volumeChange.audio'+uid, function(){
                d.gain.gain.value = d.volume / 100.0;
            })

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

    return d3.rebind(audio, commonProperties(), 'sequence','height');
}

