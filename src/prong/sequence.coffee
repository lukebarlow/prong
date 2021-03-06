d3 = require('d3-prong')
commonProperties = require('./commonProperties')
Track = require('./track/track')
Timeline = require('./components/timeline')
MusicalTimeline = require('./components/musicalTimeline')
Pool = require('./pool')
omniscience = require('omniscience')
resolveElement = require('./resolveElement')
fileToTrack = require('./fileToTrack')


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
    idsOnLastDraw = null
    timeDomain = [0, 60]
    width = 500
    x = d3.scale.linear().domain(timeDomain).range([0, width])
    editable = false

    # for now, track id is just the src attribute. May change
    ensureTracksHaveIds = (tracks) =>        
        for track in tracks
            if not track.id
                track.id = track.src or track.name


    ensureTracksHaveHeightAndOffset = (tracks) =>
        offset = 0     
        for track in tracks
            if not track.height
                track.height = trackHeight
            track.offset = offset
            offset += track.height


    setPlaylinePosition = ->
        x = sequence.x()
        [start, end] = x.domain()
        if currentTime < start or currentTime > end
            playLine.style('display','none')
        else
            position = (x(currentTime)) + propertyPanelWidth
            playLine.style('display','')
            #playLine.style('left', position + 'px')
            playLine.attr('x', position)
        

    idsKey = =>
        (tracks.map (t) => t.id).join(':')


    drawTracks = ->
        ensureTracksHaveIds(tracks)
        ensureTracksHaveHeightAndOffset(tracks)
        key = idsKey()
        if key == idsOnLastDraw
            return

        idsOnLastDraw = key
        h = sequence.height()

        container.transition().duration(500)
            .style('height', sequence.height() + 'px')

        #propertyPanel.style('height', h + 'px')
        tracksContainer.datum(tracks).call(_track)
        if playLine
            later = =>
                h = sequence.height()
                propertyPanel.style('height', h + 'px')
                playlineHeight = h - 15
                playLine.style('height', playlineHeight + 'px')
            setTimeout(later, 1)


    sequence = (_container) ->

        _container = resolveElement(_container)
        _container.html('')
        # the whole sequence is done in SVG, so if the supplied container
        # is not SVG, then we create that
        if _container.node().tagName not in ['SVG', 'G']
            _container = _container.append('svg')

        container = _container

        container
            .style('width', (sequence.width() + propertyPanelWidth) + 'px')
            .style('height', sequence.height() + 'px')
            
        x = sequence.x()
        if not x
            x = d3.scale.linear().domain(timeDomain).range([0, width])
            sequence.x(x)
        
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

        propertyPanel = container.append('g')
            .attr('class', 'propertyPanel')

        timelineContainer = container.append('g')
            .attr('transform', "translate(#{propertyPanelWidth}, 0)")
            .attr('class','timeline')
            
        timelineContainer.append('g')
            .attr('transform','translate(0,15)')
            .call(timeline)

        if musicalTime
            timelineHeight += 30
            timelineContainer.style('height', timelineHeight + 'px')
            musicalTimeline = MusicalTimeline()
                .musicalTime(musicalTime)
                .timeline(timeline)
            timelineContainer.append('g')
            .attr('transform','translate(0,45)')
            .call(musicalTimeline)

        tracksContainer = container.append('g')
            .attr('class', 'tracks')
            .attr('transform', "translate(#{propertyPanelWidth}, #{timelineHeight})")
  
        mouse = () ->
            touches = d3.event.changedTouches
            reference = timelineContainer
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
            #playLine.style('height', playlineHeight + 'px')
            #propertyPanel.style('height', sequence.height() + 'px')
            container.style('height', sequence.height() + 'px')
        
        playLine = container.append('rect')
            .attr('height', sequence.height())
            .attr('width', '1')
            .attr('class', 'playLine')
            .attr('y', 15)

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


    sequence.draw = sequence

    sequence.tracks = (_tracks) ->
        if not arguments.length then return tracks

        ensureTracksHaveIds(_tracks)
        ensureTracksHaveHeightAndOffset(_tracks)
        # this method recognises various abbreviations, and unpacks them
        # to a full track dictionary. For example, if a track is just
        # a path then it will detect the type
        Track.unpackTrackData(_tracks)
        tracks = omniscience.watch(_tracks)

        tracks.on 'change', =>
            drawTracks()

        return sequence
    

    sequence.addTrack = (track) ->
        tracks.push(track)


    sequence.addFile = (file) =>
        tracks.push(fileToTrack(file))
    

    sequence.removeTrack = (track) ->
        i = tracks.indexOf(track)
        tracks.splice(i, 1)


    sequence.fireChange = ->
        dispatch.change()
    
    
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
            else
                dispatch.tick(currentTime)

            domain = x.domain()
            # if we have played off the right hand side of the visible area,
            # then we might page over, or stop
            if currentTime > domain[1]
                if fitTimelineToAudio
                    sequence.stop()
                    sequence.currentTime(0)
                else if following
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
        return this.tracks().length * trackHeight + timelineHeight


    sequence.propertyPanelWidth = (_propertyPanelWidth) ->
        if not arguments.length then return propertyPanelWidth
        propertyPanelWidth = _propertyPanelWidth
        return sequence


    sequence.canSelectLoop = (_canSelectLoop) ->
        if not arguments.length then return canSelectLoop
        canSelectLoop = _canSelectLoop
        return sequence


    sequence.timeDomain = (_timeDomain) ->
        if not arguments.length
            return x.domain()
        x.domain(_timeDomain)
        return sequence


    sequence.width = (_width) ->
        if not arguments.length
            return x.range()[1]
        x.range([0, _width])
        return sequence


    sequence.x = (_x) ->
        if not arguments.length then return x
        x = _x
        return sequence


    sequence.editable = (_editable) ->
        if not arguments.length then return editable
        editable = _editable
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
    

    return d3.rebind(sequence, commonProperties(), 'sequence', 
            'timeline', 'historyKey')
