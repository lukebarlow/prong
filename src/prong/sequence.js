var commonProperties = require('./commonProperties'),
	Track = require('./track/track.coffee'),
	Timeline = require('./components/timeline'),
    Pool = require('./pool');

module.exports = function(){

	var element,
        tracksContainer,
        container,
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
        waveformVerticalZoom = 1,
        pool,
        dispatch = d3.dispatch('scrub','change','play','stop','tick','load','volumeChange');
        scrollZone = null
        timeline = null
        musicalTime = null
        zoomable = true
        following = true // toggle for whether the display updates to follow playback

    function setPlaylinePosition(){
        // the -2 in the next line ensures the play line is not directly
        // underneath the mouse, so you can click on tracks when scrubbing
        position = (sequence.x()(currentTime) - 2)
        if (position > sequence.width() || position < 0){
            playLine.style('display','none')
        }else{
            playLine.style('display','')
            playLine.style('left', (sequence.x()(currentTime) - 2) + 'px');
        }
    }

	function sequence(_element){
		element = _element;

		var x = sequence.x(),
		    timeline = Timeline()
                .x(x)
                .sequence(sequence)
                .zoomable(zoomable)
                .scrollZone(scrollZone || element); // create the timeline

        container = element.append('div');

        var playlineContainer = container.append('div')
                .style('position','absolute')
                .attr('class','playlineContainer');

        var timelineContainer = container.append('svg')
                .attr('height', timelineHeight)
                .attr('width', '100%')
                .attr('class','timeline')
                .append('g')
                .attr('transform','translate(0,1)')
                .call(timeline);

        tracksContainer = container.append('div')
                .attr('width', '100%');
  
        function mouse() {
            var touches = d3.event.changedTouches,
                reference = timelineContainer;

            window.reference = reference;
            return touches ? d3.touches(referece, touches)[0] : d3.mouse(reference.node());
        }

        sequence.timeline(timeline);

		// create the tracks
		_track = Track().sequence(sequence);

        tracksContainer.datum(tracks).call(_track)

		// tracksContainer.selectAll('.track')
		// 	.data(tracks)
		// 	.enter()
		// 	.append('div')
		// 	.attr('class','track')
		// 	.call(_track);

        _track.on('load', function(){
            trackLoadCount++;
            if (trackLoadCount == tracks.length){
                dispatch.load();
            }

            playLine.style('height', sequence.height() + 'px')
        })

		// and the play line
		playLine = playlineContainer.append('div')
            .style('height', '100px') // this soon gets clobbered when the tracks load
            .attr('class','playLine')
            .style('top','1px');

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
                dispatch.tick()
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

        _tracks.forEach(function(track){
            if (!('volume' in track)) track.volume = 60;
            if (!('pan' in track)) track.pan = 0;
        })
        
        // for now, track id is just the src attribute. May change
        function id(track){
            if ('id' in track) return track.id;
            if ('src' in track) return track.src;
            return track.name;
        }

        var newTracks = [];
        var existingIds = tracks.map(id);
        _tracks.forEach(function(track){
        	var trackId = id(track);
        	var existingTrackIndex = existingIds.indexOf(trackId);
        	if (existingTrackIndex != -1){
                // copy over any new string or numeric values
                var oldTrack = tracks[existingTrackIndex];
                for(var key in track){
                    if (typeof(track[key]) == 'number' || typeof(track[key]) == 'string'){
                        if (track[key] != oldTrack){
                            oldTrack[key] = track[key];
                        }
                    }
                }
        		newTracks.push(oldTrack)
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
        return sequence
    }

    playStartSequenceTime = null
    playStartComputerTime = null

    sequence.play = function(time, end, loop){
        if (playing) {
            console.log('already playing, so returning')
            return;
        }
        currentTime = time || currentTime;
        playStartSequenceTime = currentTime
        playStartComputerTime = new Date()
        playing = true;
        dispatch.play(currentTime);
        var x = sequence.x(),
            startTimestamp = Date.now(),
            startTime = currentTime;

        // this doesn't work when tab is not in focus
        d3.timer(function(){
            currentTime = ((Date.now() - startTimestamp) / 1000) + startTime;

            if (following){
                var domain = x.domain()
                if (currentTime > domain[1]){
                    var width = domain[1] - domain[0]
                    var domain = [domain[0] + width, domain[1] + width]
                    sequence.timeline().domain(domain)
                }
            }

            setPlaylinePosition();

            if (end && currentTime > end){
                if (loop){
                    dispatch.stop();
                    currentTime = time;
                    startTimestamp = Date.now();
                    startTime = currentTime;
                    dispatch.play(currentTime);
                    return false;
                }else{
                    sequence.stop();
                    return true;
                }
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
        playStartSequenceTime = null;
        playStartComputerTime = null;
        dispatch.stop();
    }

    sequence.currentTime = function(_currentTime){
        if (!arguments.length)
            // if playing then we make sure currentTime is as accurate as possible
            if (playing){
                currentTime = playStartSequenceTime + (new Date() - playStartComputerTime) / 1000;
            }
            return currentTime
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

    sequence.musicalTime = function(_musicalTime){
        if (!arguments.length) return musicalTime;
        musicalTime = _musicalTime;
        return sequence;
    }

    sequence.waveformVerticalZoom = function(_waveformVerticalZoom){
        if (!arguments.length) return waveformVerticalZoom;
        waveformVerticalZoom = _waveformVerticalZoom;
        return sequence;
    }

    sequence.trackVolume = function(trackIndex, volume){
        tracks[trackIndex].volume = volume;
        dispatch.volumeChange();
    }

    sequence.poolResources = function(resources){
        if (!arguments.length) return pool.resources();
        pool = Pool(resources);
        return sequence;
    }

    sequence.pool = function(){
        if (arguments.length){
            throw "Cannot set pool directly. Set the poolResources instead"
        }
        return pool;
    }

    sequence.scrollZone = function(_scrollZone){
        if (!arguments.length) return scrollZone
        scrollZone = _scrollZone
        return sequence;
    }

    sequence.zoomable = function(_zoomable){
        if (!arguments.length) return zoomable
        zoomable = _zoomable
        return sequence;
    }

    sequence.rangeAndDomain = function(range, domain){
        sequence.timeline().rangeAndDomain(range, domain)
    }

    sequence.height = function(){
        return container.node().clientHeight
    }

	return d3.rebind(sequence, commonProperties(), 'x', 'width', 'sequence', 'timeline');
}