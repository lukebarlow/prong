commonProperties = require('./commonProperties')
Track = require('./track/track')
Timeline = require('./components/timeline')
Pool = require('./pool')

module.exports = ->

    element = null
    tracksContainer = null
    container = null
    tracks = []
    _track = null
    playLine = null
    scrubbing = false
    playing = false
    currentTime = 0 # current time of the play line
    audioOut = null # a web audio API node which  audio from this sequence will play out of
    trackHeight = null # the default height in pixels for tracks (can be overriden for specific tracks)
    trackLoadCount = 0
    timelineHeight = 40
    waveformVerticalZoom = 1
    pool = null
    dispatch = d3.dispatch('scrub','change','play','stop','tick','load','volumeChange')
    scrollZone = null
    timeline = null
    musicalTime = null
    zoomable = true
    following = true # toggle for whether the display updates to follow playback
    propertyPanelWidth = 95

    setPlaylinePosition = ->
        # the -2 in the next line ensures the play line is not directly
        # underneath the mouse, so you can click on tracks when scrubbing
        x = sequence.x()
        [start, end] = x.domain()
        if currentTime < start or currentTime > end
            playLine.style('display','none')
        else
            position = (x(currentTime)) + propertyPanelWidth
            playLine.style('display','')
            playLine.style('left', position + 'px')
        

    sequence = (_element) ->
        element = _element
        x = sequence.x()
        timeline = Timeline()
            .x(x)
            .sequence(sequence)
            .zoomable(zoomable)
            .scrollZone(scrollZone or element) # create the timeline

        element.classed('sequence', true)

        # propertyPanel height is set after tracks are drawn
        propertyPanel = element.append('div')
            .style('width', propertyPanelWidth + 'px')
            .attr('class','propertyPanel')

        container = element.append('div')
            .attr('class','trackContainer')
            .style('left', propertyPanelWidth + 'px')

        playlineContainer = container.append('div')
            .style('position','absolute')
            .attr('class','playlineContainer')

        timelineContainer = container.append('svg')
            .attr('height', timelineHeight)
            .attr('width', '100%')
            .attr('class','timeline')
            .append('g')
            .attr('transform','translate(0,1)')
            .call(timeline)

        tracksContainer = container.append('div')
            .attr('width', '100%')
  
        mouse = () ->
            touches = d3.event.changedTouches
            reference = timelineContainer
            return if touches then d3.touches(referece, touches)[0] else d3.mouse(reference.node())

        sequence.timeline(timeline)

        # create the tracks
        _track = Track().sequence(sequence)

        tracksContainer.datum(tracks).call(_track)

        # tracksContainer.selectAll('.track')
        #   .data(tracks)
        #   .enter()
        #   .append('div')
        #   .attr('class','track')
        #   .call(_track);

        _track.on 'load', ->
            trackLoadCount++
            if trackLoadCount == tracks.length
                dispatch.load()
            playLine.style('height', sequence.height() + 'px')
            propertyPanel.style('height', sequence.height() + 'px')
        
        # and the play line
        playLine = playlineContainer.append('div')
            .style('height', '100px') # this soon gets clobbered when the tracks load
            .attr('class','playLine')
            .style('top','1px')

        setPlaylinePosition()
        timeline.on 'change.playline', ->
            setPlaylinePosition()

        timeline.on 'timeselect', (time) ->
            if not scrubbing
                currentTime = time
                setPlaylinePosition()
                if playing
                    sequence.stop()
                    sequence.play(time)
                dispatch.tick()
            
    
        # the scrubbing behavior (only works if scrubbing is set to true)
        element.on 'mousemove', ->
            if not playing and scrubbing
                mouseX = mouse()[0]
                #time = x.invert(mouseX - 100)
                time = x.invert(mouseX)
                time = Math.max(time, x.domain()[0])
                setPlaylinePosition()
                currentTime = time
                dispatch.scrub(time)


        element.on 'dblclick', ->
            if playing
                sequence.stop()
                return
            mouseX = mouse()[0]
            time = x.invert(mouseX)
            time = Math.max(time, x.domain()[0])
            sequence.play(time)


    sequence.tracks = (_tracks) ->
        if not arguments.length then return tracks
        # sometimes the track objects will have extra properties and methods
        # added to them, in which case we don't want to clobber the existing
        # objects with the new data passed to this method. So, rather than 
        # just replacing the old value of tracks with the argument passed to 
        # this method, we try to match the tracks by looking at the src 
        # attribute, then leave existing tracks as they are and add and remove
        # others as appropriate

        # this method recognises various abbreviations, and unpacks them
        # to a full track dictionary. For example, if a track is just
        # a path then it will detect the type
        Track.unpackTrackData(_tracks)

        _tracks.forEach (track) ->
            if not ('volume' of track) then track.volume = 60
            if not ('pan' of track) then track.pan = 0
        

        # for now, track id is just the src attribute. May change
        id = (track) ->
            if 'id' of track then return track.id
            if 'src' of track then return track.src
            return track.name
        

        newTracks = []
        existingIds = tracks.map(id)
        _tracks.forEach (track) ->
            trackId = id(track)
            existingTrackIndex = existingIds.indexOf(trackId)
            if existingTrackIndex != -1
                # copy over any new string or numeric values
                oldTrack = tracks[existingTrackIndex]
                for key of track
                    if typeof(track[key]) == 'number' or typeof(track[key]) == 'string'
                        if track[key] != oldTrack
                            oldTrack[key] = track[key]
                newTracks.push(oldTrack)
            else
                newTracks.push(track)
            
        tracks = newTracks
        return sequence
    

    sequence.addTrack = (track) ->
        tracks.push(track)
        sequence.redraw()
    

    sequence.removeTrack = (track) ->
        i = tracks.indexOf(track)
        tracks.splice(i,1)
        sequence.redraw()


    sequence.fireChange = ->
        dispatch.change()
    

    sequence.redraw = ->
        join = tracksContainer.selectAll('.track')
            .data(tracks, (d) -> d.src)

        join.enter()
            .append('div')
            .attr('class','track')
            .call(_track)

        join.exit()
            .each( (d,i) -> if (d.cleanup) then d.cleanup() )
            .remove()

        setPlaylinePosition()
    

    # redraws all the tracks with their contents
    sequence.redrawContents = (options) ->
        tracksContainer.selectAll('.track')
            .data(tracks, (d) ->  d.src)
            .call(_track, options)
    

    sequence.scrubbing = (_scrubbing) ->
        if not arguments.length then return scrubbing
        scrubbing = _scrubbing
        return sequence
    

    sequence.on = (type, listener) ->
        dispatch.on(type, listener)
        return sequence
    

    playStartSequenceTime = null
    playStartComputerTime = null

    sequence.play = (time, end, looping) ->
        if playing
            console.log('already playing, so returning')
            return
        
        currentTime = time or currentTime
        playStartSequenceTime = currentTime
        playStartComputerTime = new Date()
        playing = true
        dispatch.play(currentTime)
        x = sequence.x()
        startTimestamp = Date.now()
        startTime = currentTime

        # this doesn't work when tab is not in focus

        tick = ->
            currentTime = ((Date.now() - startTimestamp) / 1000) + startTime
            if following
                domain = x.domain()
                if currentTime > domain[1]
                    width = domain[1] - domain[0]
                    domain = [domain[0] + width, domain[1] + width]
                    sequence.timeline().domain(domain)
            setPlaylinePosition()
            if end and currentTime > end
                if looping
                    dispatch.stop()
                    currentTime = time
                    startTimestamp = Date.now()
                    startTime = currentTime
                    dispatch.play(currentTime)
                    return false
                else
                    sequence.stop()
                    return true
            else
                dispatch.tick(currentTime)
            return (not playing)


        d3.timer(tick, 50)

    
    sequence.playing = -> playing


    sequence.stop = ->
        playing = false
        playStartSequenceTime = null
        playStartComputerTime = null
        dispatch.stop()
    

    sequence.currentTime = (_currentTime) ->
        if not arguments.length
            # if playing then we make sure currentTime is as accurate as possible
            if playing
                currentTime = playStartSequenceTime + (new Date() - playStartComputerTime) / 1000
            return currentTime

        currentTime = _currentTime
        setPlaylinePosition()
        return sequence
    

    sequence.audioOut = (_audioOut) ->
        if not arguments.length then return audioOut
        audioOut = _audioOut
        return sequence
    

    sequence.trackHeight = (_trackHeight) ->
        if not arguments.length then return trackHeight
        trackHeight = _trackHeight
        return sequence
    

    sequence.musicalTime = (_musicalTime) ->
        if not arguments.length then return musicalTime
        musicalTime = _musicalTime
        return sequence
    

    sequence.waveformVerticalZoom = (_waveformVerticalZoom) ->
        if not arguments.length then return waveformVerticalZoom
        waveformVerticalZoom = _waveformVerticalZoom
        return sequence
    

    sequence.trackVolume = (trackIndex, volume) ->
        tracks[trackIndex].volume = volume
        dispatch.volumeChange()
    

    sequence.poolResources = (resources) ->
        if not arguments.length then return pool.resources()
        pool = Pool(resources)
        return sequence
    

    sequence.pool = ->
        if arguments.length
            throw "Cannot set pool directly. Set the poolResources instead"
        return pool
    

    sequence.scrollZone = (_scrollZone) ->
        if not arguments.length then return scrollZone
        scrollZone = _scrollZone
        return sequence
    

    sequence.zoomable = (_zoomable) ->
        if not arguments.length then return zoomable
        zoomable = _zoomable
        return sequence
    

    sequence.rangeAndDomain = (range, domain) ->
        sequence.timeline().rangeAndDomain(range, domain)
    

    sequence.height = ->
        return container.node().clientHeight


    sequence.propertyPanelWidth = (_propertyPanelWidth) ->
        if not arguments.length then return propertyPanelWidth
        propertyPanelWidth = _propertyPanelWidth
        return sequence
    

    return d3.rebind(sequence, commonProperties(), 'x', 'width', 'sequence', 'timeline')
