var commonProperties = require('./commonProperties'),
    timeline = require('./timeline');

// the container for multiple tracks
module.exports = function(){
    var width,
        tracks, // an array of track dictionaries, with the properties of each track
        playing = false,
        track, // the track component
        dispatch = d3.dispatch('change');

    // sequence keeps references to the elements it binds to, so it's more like
    // a widget than a component
    var element, player, comper, videoPlayer, playLine;

    function trackFilter(type){
        return function(track){
            return trype.type == type;
        }
    }

    function getTracksOfType(type){
        return tracks.filter(trackFilter(type));
    }


    function sequence(selection){
        var _track = track.x(sequence.x())
        selection.selectAll('.track')
            .data(tracks)

    }

    sequence.init = function(){
        var x = sequence.x();
        var width = sequence.width();
        var target = element.node();
        track = pool.track().width(width).x(x);

        // add the axis at the top
        var timeline = pool.timeline().x(x).width(width);
        var svg = element.append('svg').call(timeline);

        timeline.on('change', function(){
            var x = timeline.x();
            sequence.x(x);
            track.x(x);
            element.selectAll('.track').call(track.redraw);
            comper.x(x).redraw();
            sequence.drawOnsets();
        })

        // draw the tracks
        element.selectAll('.track')
            .data(tracks)
            .enter()
            .append('div')
            .attr('class','track')
            .call(track);

        playLine = element.append('div')
                        .attr('class','playLine')
                        .style('left',x(5) + 'px');

        // mousemove to scrub
        
        element.on('mousemove', function(){
            if (!playing){
                var videoTracks = getTracksOfType('video');
                var mouseX = mouse()[0];
                var time = x.invert(mouseX - 200);
                playLine.style('left', (mouseX - 1) + 'px');

                // move all the vidoes to the right time (so that the previews
                // also work, even for hidden tracks)
                videoTracks.forEach(function(track){
                    try {
                        track.player.currentTime = time - track.startTime;
                    }catch(e){
                        console.log('error trying to move timeline')
                    }
                    
                })

                // show the correct video according to the comping
                videoPlayer.showVideo(comper.liveTrackAtTime(time))
            }
        });

        var scrollTimeoutId = null;

        // double click to start playing from that position
        element.on('dblclick', function(){
            var mouseX = mouse()[0] - 200;
            var time = x.invert(mouseX);
            console.log('trying to play at time ' + time);
            sequence.play(time);
        });

        element.on('click', function(){
            var mouseX = mouse()[0] - 200;
            var time = x.invert(mouseX);
            console.log('time ' + time);
        });

        // create the comper
        comper = pool.comper().x(x)

        // bubble up change events
        comper.on('change', function(){
            dispatch.change();
        })

        var videoTrackSelection = element.selectAll('.track').filter(videoFilter);

        // create the video player
        videoTrackSelection.append('svg')
            .attr('width', 1000)
            .attr('height', 128)
            .attr('class','comper')
            .call(comper);

        videoPlayer = pool.videoPlayer()
                        .tracks(tracks)
                        .editList(comper.editList())
                        .element(player);
        
        // when a prepareVidoe track becomes ready, then we remove it and
        // and video and audio track instead
        track.on('videoReady', function(track){

            var newVideoTrack = { 'name' : 'mixed',
                                  'src' : 'youtube?id=' + track.sourceId,
                                  'type' : 'video',
                                  'group' :  track.sourceId
                                }
            var newAudioTrack = { 'name' : 'mixed',
                                  'src' : 'youtube-audio?id=' + track.sourceId,
                                  'type' : 'audio',
                                  'group' : track.sourceId
                                }

            // remove the track
            var index = tracks.indexOf(track);
            tracks.splice(index, 1, newVideoTrack, newAudioTrack);
            // call the setter, as this takes care of default values
            sequence.tracks(tracks);
            // and update the display
            sequence.update();
        })

        return sequence;
    }

    sequence.update = function(){

        function removePlayer(d){
            console.log('going to remove player')
            console.log(d)
            if (d.player){
                d3.select(d.player).remove();
            }
        }

        // join by the track value
        var joinedTracks = element.selectAll('.track').data(tracks, trackId);

        var removedTracks = joinedTracks.exit()
                                .transition()
                                .duration(1000)
                                .style('height','0px')
                                .each(removePlayer)
                                .remove();

        console.log('called the update');

        var newTracks = joinedTracks
                            .enter()
                            .append('div')
                            .attr('class','track');

        newTracks.call(track);

        joinedTracks.order();

        var newVideoTracks = newTracks.filter(videoFilter);

        newVideoTracks.append('svg')
            .attr('width',1000)
            .attr('height', 128)
            .attr('class','comper')

        // now update the comper with the selection of all video tracks
        comper(element.selectAll('.track').filter(videoFilter).select('.comper'));

        videoPlayer = pool.videoPlayer()
                        .tracks(tracks)
                        .editList(comper.editList())
                        .element(player);


    }

    // getter/setter for tracks
    sequence.tracks = function(_tracks, suppressEvent){
        if (!arguments.length) return tracks;
        if (arguments.length < 2) suppressEvent = false;

        // new tracks may be the same data as existing ones, in which case
        // we want to just keep the old tracks, so we merge the new track list
        // with the existing one
        var existingTrackIds = tracks ? tracks.map(trackId) : [];

        var mergedTracks = [];
        _tracks.forEach(function(track,i){
            var matchingIndex = existingTrackIds.indexOf(trackId(track));
            if (matchingIndex != -1){
                mergedTracks.push(tracks[matchingIndex])
            }else{
                mergedTracks.push(track)
            }
        })

        tracks = mergedTracks;
        if (videoPlayer) videoPlayer.tracks(_tracks);
        tracks.forEach(function(track){
            if (!('startTime' in track)){
                track.startTime = 0
            }
        });

        if (!suppressEvent){
            dispatch.change();
        }

        return sequence;
    }

    // returns the note onset arrays for each track, and sets them on the
    // track dictionaries
    sequence.calculateOnsets = function(threshold, compressionFactor, windowSize){

        var audioTracks = getTracksOfType('audio')

        audioTracks.forEach(function(track){
            var onsetTimes = pool.noteOnset(track.channel, 
                track.buffer.sampleRate, threshold, compressionFactor, windowSize)
            var onsetDiffs = d3.map()
            var decimalPlaces = 3

            for (var i=1;i<onsetTimes.length;i++){
                for (j=1;j<=i;j++){
                    onsetDiffs.set(d3.round(onsetTimes[i]-onsetTimes[i-j],decimalPlaces),onsetTimes[i])
                }
            }

            track.onsetTimes = onsetTimes
            track.onsetDiffs = onsetDiffs
        })
        return tracks[0].onsetTimes
    }

    // this method should be called in the context of a d3 selection of the
    // container element for the sequence. It will draw the onset lines. Note
    // that you must have previously called sequence.calculateOnsets
    sequence.drawOnsets = function(){
        var x = sequence.x();
        element.selectAll('.track').each(function(track, i){
                if (!track.onsetTimes) return;
                var waveform = d3.select(this).select('.waveform');
                // remove any existing onset lines
                waveform.selectAll('.onset').remove()
                // now draw the new ones
                waveform.selectAll('.onset')
                    .data(track.onsetTimes)
                    .enter()
                    .append('rect')
                    .attr('class','onset')
                    .attr('x', function(d){
                        return x(d + track.startTime);
                    })
                    .attr('width',1)
                    .attr('y', 0)
                    .attr('height', 256)
            })
    }

    // looks for the best match of time differences between offsets, and
    // so sets the start time for each track. Returns true if it managed to
    // match all tracks, or false if it didn't
    sequence.calculateBestStartTimes = function(){
        // we compare each track with the first one
        var audioTracks = getTracksOfType('audio')
        var a = audioTracks[0].onsetDiffs
        for (var i=1;i<audioTracks.length;i++){
            var b = audioTracks[i].onsetDiffs
            var timeDiffs = d3.map()
            a.forEach(function(key,value){
                if (b.has(key)){
                    var diff = d3.round(value - b.get(key),3)
                    if (timeDiffs.has(diff)){
                        timeDiffs.set(diff, timeDiffs.get(diff) + 1);
                    }else{
                        timeDiffs.set(diff,1);
                    }
                }
            })

            var values = timeDiffs.values()
            var maxMatches = d3.max(values)

            if (maxMatches >= 5){
                var bestDiff = timeDiffs.keys()[values.indexOf(maxMatches)]
                // var trackToMove = bestDiff > 0 ? i : i+1
                // bestDiff = Math.abs(bestDiff)
                trackToMove = i
                audioTracks[trackToMove].startTime = bestDiff
            }
        }

        // finally, we move all start times forward so the earliest track
        // starts at zero
        var minStartTime = d3.min(audioTracks, function(track){return track.startTime})
        audioTracks.forEach(function(track){track.startTime -= minStartTime})

        // now the video tracks just copy the start times of the audio
        // track with the same src attribute
        var videoTracks = getTracksOfType('video')
        videoTracks.forEach(function(videoTrack){
            var audioTrack = audioTracks.filter(function(track){
                return track.group == videoTrack.group
            })[0]
            if (audioTrack) videoTrack.startTime = audioTrack.startTime
        });
        dispatch.change();
    }

    // should be called in the context of a selection of the div containing
    // the sequence. This will move all the tracks to the calculated
    // start position
    sequence.moveToBestStartTimes = function(){
        var x = sequence.x();
        element.selectAll('.track')
            .each(function(track){
                var movement = x(track.startTime) - x(0);
                switch(track.type){
                    case 'audio' :
                        d3.select(this).select('.waveform')
                            .transition()
                            .duration(1000)
                            .attr('transform','translate('+movement+',0)')
                    break;
                    case 'video' :
                        d3.select(this).select('canvas')
                            .transition()
                            .duration(1000)
                            .style('left',movement+'px')
                    break;
                }
            })
    }

    sequence.play = function(time){
        var x = sequence.x();
        time = time || 0;
        playing = true;
        videoPlayer.play(time)

        var endTime = x.domain()[1]

        playLine.style('left', (x(time) + 200) + 'px')
                .transition()
                .duration((endTime - time) * 1000)
                .style('left', (x(endTime) + 200) + 'px')
                .ease(d3.ease('linear'));
        
    }



    // getter/setter for the main element it binds to
    sequence.element = function(_element){
        if (!arguments.length) return element;
        if (typeof(_element) == 'string'){
            _element = d3.select(_element)
        }
        element = _element;
        return sequence;
    }

    // getter/setter for the player element
    sequence.player = function(_player){
        if (!arguments.length) return player;
        if (typeof(_player) == 'string'){
            _player = d3.select(_player)
        }
        player = _player;
        return sequence;
    }


    sequence.on = function(type, listener){
        dispatch.on(type, listener)
    }

    return d3.rebind(sequence, commonProperties(), 'x', 'width');
}