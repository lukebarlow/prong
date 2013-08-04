var commonProperties = require('./commonProperties'),
	Track = require('./track/track'),
	Timeline = require('./components/timeline');

module.exports = function(){

	var element,
        tracksContainer,
        tracks = [],
        _track,
        playLine,
        scrubbing = false,
        playing = false,
        currentTime = 0, // current time of the play line
        audioOut, // a web audio API node which  audio from this sequence will play out of
        trackHeight, // the default height in pixels for tracks (can be overriden for specific tracks)
        trackLoadCount = 0,
        timelineHeight = 40,
        dispatch = d3.dispatch('scrub','change','play','stop','tick','load','volumeChange');

    function setPlaylinePosition(){
        // the -1 in the next line ensures the play line is not directly
        // underneath the mouse, so you can click on tracks when scrubbing
        playLine.style('left', (sequence.x()(currentTime) - 2) + 'px');
    }

	function sequence(_element){
		element = _element;

		var x = sequence.x(),
		    timeline = Timeline().x(x).scrollZone(element), // create the timeline
            absoluteContainer = element.append('div')
                .style('position','absolute'),
            timelineContainer = absoluteContainer.append('svg')
                .attr('height', timelineHeight)
                .call(timeline);

        tracksContainer = absoluteContainer.append('div')
                .style('position','absolute');

        var playlineContainer = absoluteContainer.append('div')
                .style('position','absolute')
                .style('top', '0px');
            
        function mouse() {
            var touches = d3.event.changedTouches,
                reference = timelineContainer;


            window.reference = reference;
            return touches ? d3.touches(referece, touches)[0] : d3.mouse(reference.node());
        }

        sequence.timeline(timeline);

		// create the tracks
		_track = Track().sequence(sequence);
		tracksContainer.selectAll('.track')
			.data(tracks)
			.enter()
			.append('div')
			.attr('class','track')
			.call(_track);

        _track.on('load', function(){
            trackLoadCount++;
            if (trackLoadCount == tracks.length){
                dispatch.load();
            }

            var totalTrackHeight = d3.sum(tracksContainer.selectAll('.track')[0], function(t){
                return t.clientHeight;
            })

            playLine.style('height', (totalTrackHeight + timelineHeight) + 'px');

        })

		// and the play line
		playLine = playlineContainer.append('div')
            .style('height', '200px') // this soon gets clobbered when the tracks load
            .attr('class','playLine');

        setPlaylinePosition();
        timeline.on('change.playline', function(){
        	setPlaylinePosition();
        })

        timeline.on('timeselect', function(time){
            if (!scrubbing){
                currentTime = time;
                setPlaylinePosition();
                if (playing){
                    sequence.stop();
                    sequence.play(time);
                }
            }
        })

        // the scrubbing behavior (only works if scrubbing is set to true)
        element.on('mousemove', function(){
            if (!playing && scrubbing){
                var mouseX = mouse()[0];
                //var time = x.invert(mouseX - 100);
                var time = x.invert(mouseX)
                time = Math.max(time, x.domain()[0])
                setPlaylinePosition();
                currentTime = time;
                dispatch.scrub(time);
            }
        });

        element.on('dblclick', function(){
            if (playing) {
                sequence.stop();
                return;
            }
            var mouseX = mouse()[0];
            var time = x.invert(mouseX);
            time = Math.max(time, x.domain()[0])
            sequence.play(time);
        });
	}

	sequence.tracks = function(_tracks){
        if (!arguments.length) return tracks;
        // sometimes the track objects will have extra properties and methods
        // added to them, in which case we don't want to clobber the existing
        // objects with the new data passed to this method. So, rather than 
        // just replacing the old value of tracks with the argument passed to 
        // this method, we try to match the tracks by looking at the src 
        // attribute, then leave existing tracks as they are and add and remove
        // others as appropriate

        // this method recognises various abbreviations, and unpacks them
        // to a full track dictionary. For example, if a track is just
        // a path then it will detect the type
        Track.unpackTrackData(_tracks);

        // for now, track id is just the src attribute. May change
        function id(track){return track.src}

        var newTracks = [];
        var existingIds = tracks.map(id);
        _tracks.forEach(function(track){
        	var trackId = id(track);
        	var existingTrackIndex = existingIds.indexOf(trackId);
        	if (existingTrackIndex != -1){
        		newTracks.push(tracks[existingTrackIndex])
        	}else{
        		newTracks.push(track);
        	}
        })
        tracks = newTracks;
        return sequence;
    }

    sequence.addTrack = function(track){
    	tracks.push(track);
    	sequence.redraw();
    }

    sequence.removeTrack = function(track){
        var i = tracks.indexOf(track);
        tracks.splice(i,1);
        sequence.redraw();
    }

    sequence.fireChange = function(){
        dispatch.change();
    }

    sequence.redraw = function(){
    	var join = tracksContainer.selectAll('.track')
			.data(tracks, function(d){return d.src})

		join.enter()
			.append('div')
			.attr('class','track')
			.call(_track);

		join.exit()
			.each(function(d,i){ if (d.cleanup) d.cleanup()})
			.remove();

        setPlaylinePosition();
    }

    // redraws all the tracks with their contents
    sequence.redrawContents = function(options){
        tracksContainer.selectAll('.track')
            .data(tracks, function(d){return d.src})
            .call(_track, options)
    }

    sequence.scrubbing = function(_scrubbing){
        if (!arguments.length) return scrubbing;
        scrubbing = _scrubbing;
        return sequence;
    }

    sequence.on = function(type, listener){
        dispatch.on(type, listener)
    }

    sequence.play = function(time, end){
        currentTime = time || currentTime;
        playing = true;
        dispatch.play(currentTime);
        var x = sequence.x();
            startTimestamp = Date.now(),
            startTime = currentTime;

        d3.timer(function(){
            currentTime = ((Date.now() - startTimestamp) / 1000) + startTime;
            setPlaylinePosition();
            if (end && currentTime > end){
                sequence.stop();
                return true;
            }else{
                dispatch.tick(currentTime);
            }
            return !(playing);
        },50);
    }

    sequence.playing = function(){
        return playing;
    }

    sequence.stop = function(){
        playing = false;
        dispatch.stop();
    }

    sequence.currentTime = function(_currentTime){
        if (!arguments.length) return currentTime;
        currentTime = _currentTime;
        setPlaylinePosition();
        return sequence;
    }

    sequence.audioOut = function(_audioOut){
        if (!arguments.length) return audioOut;
        audioOut = _audioOut;
        return sequence;
    }

    sequence.trackHeight = function(_trackHeight){
        if (!arguments.length) return trackHeight;
        trackHeight = _trackHeight;
        return sequence;
    }

    sequence.trackVolume = function(trackIndex, volume){
        tracks[trackIndex].volume = volume;
        dispatch.volumeChange();
    }

	return d3.rebind(sequence, commonProperties(), 'x', 'width', 'sequence', 'timeline');
}