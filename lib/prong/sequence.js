var commonProperties = require('./commonProperties'),
	Track = require('./track/track'),
	Timeline = require('./timeline');

module.exports = function(){

	var element, 
        tracks = [], 
        timeline, 
        _track,
        scrubbing = false,
        playing = false,
        currentTime = 0,
        audioOut,
        dispatch = d3.dispatch('scrub','change','play','stop','tick');

    function mouse() {
        var touches = d3.event.changedTouches;
        return touches ? d3.touches(element, touches)[0] : d3.mouse(element.node());
    }

    function setPlaylinePosition(){
        playLine.style('left', x(currentTime) + 'px');
    }

	function sequence(_element){
		element = _element;
		element.style('position','absolute');
		var x = sequence.x();
		
		// create the timeline
		timeline = Timeline().x(x).scrollZone(element);
		var svg = element.append('svg').call(timeline);

		// create the tracks
		_track = Track().sequence(sequence);
		element.selectAll('.track')
			.data(tracks)
			.enter()
			.append('div')
			.attr('class','track')
			.call(_track);

		// and the play line
		playLine = element.append('div')
            .attr('class','playLine');

        setPlaylinePosition();
        timeline.on('change.playline', function(){
        	setPlaylinePosition();
        })

        // the scrubbing behavior (only works if scrubbing is set to true)
        element.on('mousemove', function(){
            if (!playing && scrubbing){
                var mouseX = mouse()[0];
                var time = x.invert(mouseX - 100);
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
            var time = x.invert(mouseX - 100);
            time = Math.max(time, x.domain()[0])
            sequence.play(time);
            
        })
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

    sequence.timeline = function(_timeline){
        if (!arguments.length) return timeline;
        timeline = _timeline;
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
    	var join = element.selectAll('.track')
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
        element.selectAll('.track')
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
        time = time || currentTime;
        playing = true;
        dispatch.play(time);
        var endTime = x.domain()[1];
        var startTimestamp = Date.now();
        var startTime = time;
        d3.timer(function(){
            time = ((Date.now() - startTimestamp) / 1000) + startTime;
            playLine.style('left', x(time) + 'px');
            currentTime = time;
            if (time > end){
                sequence.stop();
                return true;
            }else{
                dispatch.tick(time);
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

	return d3.rebind(sequence, commonProperties(), 'x', 'width');
}