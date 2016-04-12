d3 = require('d3-prong')
commonProperties = require('./commonProperties')
Track = require('./track/track')
Timeline = require('./components/timeline')
MusicalTimeline = require('./components/musicalTimeline')
Pool = require('./pool')
omniscience = require('./omniscience')


module.exports = ->

    container = null
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
    dispatch = d3.dispatch('scrub','change','play','stop','loop','tick',
        'load', 'timeselect')
    scrollZone = null
    timeline = null
    musicalTime = null
    zoomable = true
    scrollable = true
    following = true # toggle for whether the display updates to follow playback
    propertyPanelWidth = 95
    canSelectLoop = false
    loopDomain = [null, null] # only to store domain before timeline created
    loopDisabled = false
    fitTimelineToAudio = false
    playLine = null
    propertyPanel = null

    setPlaylinePosition = ->
        x = sequence.x()
        [start, end] = x.domain()
        if currentTime < start or currentTime > end
            playLine.style('display','none')
        else
            position = (x(currentTime)) + propertyPanelWidth
            playLine.style('display','')
            playLine.style('left', position + 'px')
        

    drawTracks = ->
        propertyPanel.style('height', sequence.height() + 'px')
        if playLine
            playlineHeight = sequence.height() - 15
            playLine.style('height', playlineHeight + 'px')
        tracksContainer.datum(tracks).call(_track)


    sequence = (_container) ->
        container = _container
        x = sequence.x()
        timeline = Timeline()
            .x(x)
            .sequence(sequence)
            .zoomable(zoomable)
            .scrollable(scrollable)
            .canSelectLoop(canSelectLoop)
            .scrollZone(scrollZone or container) # create the timeline
            .loop(loopDomain)
            .loopDisabled(loopDisabled)


        if historyKey = sequence.historyKey()
            timeline.historyKey(historyKey+'tl')

        container.classed('sequence', true)

        # propertyPanel height is set after tracks are drawn
        propertyPanel = container.append('div')
            .style('width', propertyPanelWidth + 'px')
            .style('height', "#{tracks.length * trackHeight + timelineHeight}px")
            .attr('class','propertyPanel')

        container = container.append('div')
            .attr('class','trackContainer')
            .style('left', propertyPanelWidth + 'px')

        playlineContainer = container.append('div')
            .style('position','absolute')
            .attr('class','playlineContainer')

        timelineContainer = container.append('div')
            .style('height', timelineHeight + 'px')
            .style('width', '100%')
            .attr('class', 'timelineContainer')

        timelineSvg = timelineContainer.append('svg')
            .style('position', 'absolute')
            #.style('z-index', -1)
            .attr('height', 80)
            .attr('width', '100%')
            .attr('class','timeline')
            
        timelineSvg.append('g')
            .attr('transform','translate(0,15)')
            .call(timeline)

        if musicalTime
            timelineHeight += 30
            timelineContainer.style('height', timelineHeight + 'px')
            musicalTimeline = MusicalTimeline()
                .musicalTime(musicalTime)
                .timeline(timeline)
            timelineSvg.append('g')
            .attr('transform','translate(0,45)')
            .call(musicalTimeline)

        tracksContainer = container.append('div')
            .attr('width', '100%')
  
        mouse = () ->
            touches = d3.event.changedTouches
            reference = timelineSvg
            return if touches then d3.touches(referece, touches)[0] else d3.mouse(reference.node())

        sequence.timeline(timeline)

        # create the tracks
        _track = Track().sequence(sequence)

        drawTracks()

        _track.on 'load', ->
            trackLoadCount++

            # if we have the 'fitTimelineToAudio' feature then we adjust the
            # timeline to the longest track
            if fitTimelineToAudio
                longest = d3.max tracks, (track) => 
                    if track._buffer then track._buffer.duration else 0
                if longest != x.domain()[1]
                    x.domain([0, longest])
                    timeline.x(x).fireChange()

            if trackLoadCount == tracks.length
                dispatch.load()

            playlineHeight = sequence.height() - 15
            playLine.style('height', playlineHeight + 'px')
            propertyPanel.style('height', sequence.height() + 'px')
        
        # and the play line
        playLine = playlineContainer.append('div')
            .style('height', '100px') # this soon gets clobbered when the tracks load
            .attr('class','playLine')
            .style('top','15px')

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
            dispatch.timeselect()

        # the scrubbing behavior (only works if scrubbing is set to true)
        container.on 'mousemove', ->
            if not playing and scrubbing
                mouseX = mouse()[0]
                #time = x.invert(mouseX - 100)
                time = x.invert(mouseX)
                time = Math.max(time, x.domain()[0])
                setPlaylinePosition()
                currentTime = time
                dispatch.scrub(time)


        container.on 'dblclick', ->
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

        # replace each track with a proxy, and give it a watch method
        # which can be used to listen for changes
        # _tracks = _tracks.map (track) =>
        #     dispatch = d3.dispatch('change')
        #     handler = {
        #         set: (target, property, value, receiver) =>
        #             console.log('set a value', target, property, value, receiver)
        #     }
        #     proxy = new Proxy(track, handler)
        #     return proxy

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
            
        tracks = omniscience.makeWatchable(newTracks)

        #omniscience.makeWatchable(tracks)
        # if sequence.historyKey()
        #     tracks.forEach (track) =>
        #         track.watch 'automation', =>
        #             console.log('saw an automation change in tracks')


        omniscience.watch tracks, () =>
            drawTracks()

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

    sequence.play = (time) ->

        if playing
            console.log('already playing, so returning')
            return
        
        [loopStart, loopEnd] = timeline.loop()
 
        if time == undefined and loopStart!= null and loopEnd != null and (not timeline.loopDisabled())
            time = loopStart

        currentTime = if time != undefined then time else currentTime
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
            
            [loopStart, loopEnd] = sequence.loop()
            looping = (not sequence.loopDisabled()) and loopStart != null

            # the 'currentTime < loopStart' bit allows you to scrub. It does
            # not follow the behavior of other sequencers
            if looping and (currentTime > loopEnd or currentTime < loopStart)
                #dispatch.stop()
                currentTime = loopStart
                playStartSequenceTime = currentTime
                playStartComputerTime = new Date()
                startTimestamp = Date.now()
                startTime = currentTime
                setPlaylinePosition()
                dispatch.loop(loopStart)
                return false

                # else
                #     sequence.stop()
                #     currentTime = end
                #     setPlaylinePosition()
                #     return true
            else
                dispatch.tick(currentTime)

            if following
                domain = x.domain()
                if currentTime > domain[1]
                    width = domain[1] - domain[0]
                    domain = [domain[0] + width, domain[1] + width]
                    sequence.timeline().domain(domain)
            setPlaylinePosition()

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


    sequence.scrollable = (_scrollable) ->
        if not arguments.length then return scrollable
        scrollable = _scrollable
        return sequence


    sequence.fitTimelineToAudio = (_fitTimelineToAudio) ->
        if not arguments.length then return fitTimelineToAudio
        fitTimelineToAudio = _fitTimelineToAudio
        return sequence
    

    sequence.rangeAndDomain = (range, domain) ->
        sequence.timeline().rangeAndDomain(range, domain)
    

    sequence.height = ->
        return container.node().clientHeight


    sequence.propertyPanelWidth = (_propertyPanelWidth) ->
        if not arguments.length then return propertyPanelWidth
        propertyPanelWidth = _propertyPanelWidth
        return sequence


    sequence.canSelectLoop = (_canSelectLoop) ->
        if not arguments.length then return canSelectLoop
        canSelectLoop = _canSelectLoop
        return sequence


    sequence.loop = (domain) ->
        if not arguments.length
            if timeline
                return timeline.loop()
            else
                return loopDomain or [null, null]
        if timeline
            timeline.loop(domain)
        else
            loopDomain = domain
        canSelectLoop = true
        return sequence


    sequence.loopDisabled = (_loopDisabled) ->
        if not arguments.length
            if timeline
                return timeline.loopDisabled()
            else
                return loopDisabled
        if timeline
            timeline.loopDisabled(_loopDisabled)
        else
            loopDisabled = _loopDisabled
        canSelectLoop = true
        return sequence
    

    return d3.rebind(sequence, commonProperties(), 'x', 'width', 'sequence', 
            'timeline', 'historyKey')
