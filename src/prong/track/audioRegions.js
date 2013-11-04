var commonProperties = require('../commonProperties'),
    uid = require('../uid'),
    Waveform = require('../components/waveform.js');

var regionCounter = 0;

/*
Constructs the audio out for the track, with gain and panner, and sets up
the event handler so that the regions will play the right audio at the right
time when the sequence is played.
*/
function setPlayHandler(track){

    var regions = track.regions;

    var audioOut = sequence.audioOut();
    if (!audioOut) return;
    var audioContext = prong.audioContext();

    var gain = audioContext.createGain();
    var panner = audioContext.createPanner();

    function setVolume(){
        gain.gain.value = track.volume / 100.0;
    }

    track.watch('volume', function(){
        setVolume();
    });

    setVolume();

    function setPan(){
        // pan numbers are between -64 and +63. We convert this
        // into an angle in radians, and then into an x,y position
        var angle = (track.pan || 0) / 64 * Math.PI * 0.5,
            x = Math.sin(angle) / 2,
            y = Math.cos(angle) / 2;
        panner.setPosition(x, y, 0);
    }

    track.watch('pan', function(){
        setPan();
    })

    setPan();
    gain.connect(panner);
    panner.connect(audioOut);
    var trackOut = gain;

    sequence.on('play.audio'+uid(), function(){

        regions.forEach(stop);

        regions.forEach(function(region){
            // if no audio buffer, then can't play
            if (!region.buffer) return;
            // if this region is already in the past, then skip
            if (sequence.currentTime() > 
                region.startTime + (region.clipEnd - region.clipStart)) return;

            var timeOffset = sequence.currentTime() - (region.startTime || 0),
                timeUntilStart = timeOffset < 0 ? 0 - timeOffset : 0,
                when = timeOffset < 0 ? audioContext.currentTime - timeOffset : audioContext.currentTime,
                offset = timeOffset > region.clipStart ? timeOffset + region.clipStart : region.clipStart,
                playingTime = region.clipEnd - region.clipStart - (timeOffset > 0 ? timeOffset : 0);

            var source = audioContext.createBufferSource();
            source.buffer = region.buffer;
            region.source = source;
            source.connect(trackOut);
            source.start(when, offset);
            source.stop(when + playingTime);
        });
    });
}

function setStopHandler(d){
    sequence.on('stop.audio'+uid(), function(){
        stop(d);
    });
}

function stop(region){
    if (region.source){
        region.source.stop(0)
    };
    delete region.source;
}

module.exports = function(){
    function audioRegions(selection){

        var sequence = audioRegions.sequence(),
            x = sequence.x(),
            width = sequence.width();
            
        selection.each(function(track,i){

            var div = d3.select(this),
                height = track.height || sequence.trackHeight() || 128;

            var svg = div.append('svg')
                .attr('height',height)
                .attr('width',width)
                .on('mouseover', function(d){
                    d3.select(this).classed('over', true);
                    d.over = true;
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

            svg.selectAll('g')
                .data(track.regions)
                .enter()
                .append('g')
                .attr('class','audioRegion')
                .append('rect')
                .attr('x', function(d){return x(d.startTime)})
                .attr('width', function(d){
                    return x(d.clipEnd) - x(d.clipStart);
                })
                .attr('y',0)
                .attr('height',height)
                .each(setStopHandler)

            div.append('span').text(prong.trackName).attr('class','trackName');

            setPlayHandler(track);

        })

        // when the pool is loaded, draw the waveforms
        //sequence.pool().onloaded(function(){
        var waveform = Waveform()
            .x(x)
            .height(sequence.trackHeight() || 128)
            .timeline(sequence.timeline());

        selection.selectAll('g.audioRegion')
            .each(function(d,i){
                var thiz = d3.select(this);
                sequence.pool().getBufferForId(d.clipId, function(buffer){
                    d.buffer = buffer;
                    d.channel = d.buffer.getChannelData(0)
                    thiz.call(waveform);
                });
            })

        sequence.timeline().on('change.' + uid(), function(){
            selection.selectAll('.audioRegion')
                .selectAll('rect')
                .attr('x', function(d){return x(d.startTime)})
                .attr('width', function(d){
                    return x(d.clipEnd) - x(d.clipStart);
                })
        })
    }

    return d3.rebind(audioRegions, commonProperties(), 'sequence','height');
}