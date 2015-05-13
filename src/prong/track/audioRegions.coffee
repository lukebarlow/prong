d3 = require('../d3-prong-min')
commonProperties = require('../commonProperties')
uid = require('../uid')
Waveform = require('../components/waveform')

regionCounter = 0

###
Constructs the audio out for the track, with gain and panner, and sets up
the event handler so that the regions will play the right audio at the right
time when the sequence is played.
###
setPlayHandler = (track) ->

    regions = track.regions

    audioOut = sequence.audioOut()
    if (!audioOut) then return
    audioContext = prong.audioContext()

    gain = audioContext.createGain()
    panner = audioContext.createPanner()

    # volume
    setVolume = ->
        gain.gain.value = track.volume / 100.0
    track.watch( 'volume', -> setVolume() )
    setVolume()

    # pan
    setPan = ->
        # pan numbers are between -64 and +63. We convert this
        # into an angle in radians, and then into an x,y position
        angle = track.pan / 64 * Math.PI * 0.5
        x = Math.sin(angle) / 2
        y = Math.cos(angle) / 2
        panner.setPosition(x, y, 0)
    track.watch('pan', -> setPan() )
    setPan()

    gain.connect(panner)
    panner.connect(audioOut)
    trackOut = gain

    
    play = ->
        regions.forEach(stop)

        regions.forEach (region) ->
            # if no audio buffer, then can't play
            if not region._clip then return
            # if this region is already in the past, then skip
            if (sequence.currentTime() > region.startTime + (region.clipEnd - region.clipStart)) then return

            timeOffset = sequence.currentTime() - (region.startTime || 0)
            timeUntilStart = if timeOffset < 0 then 0 - timeOffset else 0
            whenToStart = if timeOffset < 0 then audioContext.currentTime - timeOffset else audioContext.currentTime
            offset = if timeOffset > region.clipStart then timeOffset + region.clipStart else region.clipStart
            playingTime = region.clipEnd - region.clipStart - (if timeOffset > 0 then timeOffset else 0)

            source = audioContext.createBufferSource()
            source.buffer = region._clip._buffer
            region._source = source
            source.connect(trackOut)
            source.start(whenToStart, offset)
            source.stop(whenToStart + playingTime)

    stop = ->
        regions.forEach (region) ->
            if region._source
                region._source.stop(0)
                delete region._source

    loopHandler = ->
        stop()
        play()

    _uid = uid()

    sequence.on('play.region'+_uid, play)
    sequence.on('stop.region'+_uid, stop)
    sequence.on('loop.region'+_uid, loopHandler)



# setStopHandler = (d) ->
#     sequence.on 'stop.audio'+uid(), ->
#         stop(d)


# stop = (region) ->
#     if region._source
#         region._source.stop(0)
#     delete region._source


module.exports = ->

    dispatch = d3.dispatch('load')

    audioRegions = (selection) ->

        sequence = audioRegions.sequence()
        x = sequence.x()
        width = sequence.width()
            
        selection.each (track,i) ->

            div = d3.select(this)
            height = track.height || sequence.trackHeight() || 128

            div.append('div').attr('class','trackName').append('span').text(prong.trackName)

            svg = div.append('svg')
                .attr('height',height)
                .attr('width',width)
                .on 'mouseover', (d) ->
                    if not prong._dragging
                        d3.select(this).classed('over', true)
                        d.over = true
                .on 'mouseout', (d) ->
                    d3.select(this).classed('over', false)
                    d.over = false
                .each (d) ->
                    d.watch 'over', ->
                        svg.classed('over', d.over)

            svg.selectAll('g')
                .data(track.regions)
                .enter()
                .append('g')
                .attr('class','audioRegion')
                .append('rect')
                .attr('x', (d) -> x(d.startTime) )
                .attr('width', (d) -> x(d.clipEnd) - x(d.clipStart) )
                .attr('y',0)
                .attr('height', height)
                #.each(setStopHandler)

            setPlayHandler(track)


        # when the pool is loaded, draw the waveforms
        waveform = Waveform()
            .x(x)
            .height(sequence.trackHeight() || 128)
            .timeline(sequence.timeline())


        selection.selectAll('g.audioRegion')
            .each (d,i) ->
                container = d3.select(this)
                sequence.pool().getClipById d.clipId, (clip) ->
                    # d._resource
                    # d._buffer = buffer
                    # d._channel = buffer.getChannelData(0)
                    d._clip = clip
                    container.call(waveform)
                    dispatch.load(d)
            

        sequence.timeline().on 'change.' + uid(), ->
            selection.selectAll('.audioRegion')
                .selectAll('rect')
                .attr('x', (d) -> x(d.startTime) )
                .attr('width', (d) -> x(d.clipEnd) - x(d.clipStart) )
        

    audioRegions.on = (type, listener) ->
        dispatch.on(type, listener)
        return audioRegions


    return d3.rebind(audioRegions, commonProperties(), 'sequence','height')
