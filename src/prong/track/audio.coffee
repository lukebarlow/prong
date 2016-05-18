d3 = require('d3-prong')
commonProperties = require('../commonProperties')
sound = require('../sound').sound
Waveform = require('../components/waveform')
Automation = require('../components/automation')
Onsets = require('../components/onsets')
uid = require('../uid')
global = require('../prongGlobal')
trackName = require('../trackName')
AudioContext = require('../audioContext')
omniscience = require('omniscience')
#Lines = require('../components/lines')
#Note = require('../components/note')

DEFAULT_VOLUME = 60
DEFAULT_PAN = 0

# audioTrack is responsible for drawing out the audio tracks. This is a
# container for different representations of audio (waveform and/or spectrogram)
module.exports = ->
    width = null
    dispatch = d3.dispatch('load', 'automationChange')

    # gets the first non blank channel in a buffer
    getFirstNonBlankChannel = (buffer) ->
        nonBlankChannels = getNonBlankChannelIndexes(buffer)
        if (nonBlankChannels.length > 0)
            return buffer.getChannelData(nonBlankChannels[0])
    

    getNonBlankChannelIndexes = (buffer) ->
        nonBlankChannels = []
        for i in [0...buffer.numberOfChannels]
            channel = buffer.getChannelData(i)
            someNonZero = channel.some( (value) -> value > 0 )
            if someNonZero
                nonBlankChannels.push(i)    
        return nonBlankChannels


    # the default sound loader
    httpSoundLoader = (loadingMessage, callback) ->
        track = this
        
        onprogress = (message) ->
            loadingMessage.text(message)

        onloaded = (buffer) ->
            track._buffer = buffer
            track._channel = getFirstNonBlankChannel(track._buffer)
            callback()

        sound(track.src, onloaded, onprogress)
    

    audio = (selection) ->

        selection.each (d,i) ->
            d = omniscience.watch(d)

            if not ('volume' of d)
                d.volume = DEFAULT_VOLUME
            if not ('pan' of d)
                d.pan = DEFAULT_PAN

            sequence = audio.sequence()
            x = sequence.x()
            width = sequence.width()
            height = d.height || sequence.trackHeight() || 128
            div = d3.select(this)

            if not ('volume' of d) then d.volume = 1

            div.append('div').attr('class','trackName').append('span').text(trackName)
            loadingMessage = div.append('span').attr('class','trackLoading')

            svg = div.append('svg')
                .attr('height',height)
                .attr('width', '100%')
                .on 'mouseover', (d) ->
                    if not global._dragging
                        d3.select(this).classed('over', true)
                        d.over = true
                .on 'mouseout', (d) ->
                    d3.select(this).classed('over', false)
                    d.over = false

            middleground = svg.append('g').attr('class', 'middleground')
            foreground = svg.append('g').attr('class', 'foreground')
  
            src = d.audioSrc || d.src

            # each track has a 'loader' method which is responsible for
            # asynchronously loading and decoding the data, and reporting
            # on progress as it goes. The default one loads from http. Once
            # the loader is complete, the track should have channel and
            # buffer properties
            if not (d._loader)
                if '_channel' of d
                    # if we already have a channel set, set a 'do nothing' loader
                    d._loader = (_,callback) ->
                        setTimeout(callback, 1)
                else
                    d._loader = httpSoundLoader

            d._loader loadingMessage, ->
                d._loader = null
                loadingMessage.remove()
                waveform = Waveform()
                    .x(x)
                    .height(height)
                    .verticalZoom(sequence.waveformVerticalZoom())
                    .timeline(sequence.timeline())

                automation = Automation()
                    .height(height)
                    .timeline(sequence.timeline())
                    .key('volume')

                middleground.call(waveform)
                foreground.call(automation)

                #console.log('just finished loading')
                if sequence.playing()
                    play()

                dispatch.load(d)

            _uid = uid()
            playing = false

            lastVolumePointBeforeNow = =>
                timeOffset = sequence.currentTime() - (d.startTime || 0)
                points = d.automation.volume.points
                i = 0
                while points.length > (i + 1) and points[i+1][0] < timeOffset
                    i++
                return points[i]

            setVolumeAndPan = =>
                if d._gain
                    d._gain.gain.value = d.volume / 100.0
                if d._panner
                    d._panner.pan.value = d.pan / 64

                # if the fader volume disagrees with what we would expect from
                # the automation curves, then we add a point to the automation
                if d.automation and d.automation.volume and playing and d.dragging
                    expectedVolume = lastVolumePointBeforeNow()[1]
                    if d.volume != expectedVolume
                        timeOffset = sequence.currentTime() - (d.startTime || 0)
                        timeOffset = d3.round(timeOffset, 3)
                        # now look through the points for the correct place to
                        # insert this new automation point. If it's too close
                        # to an existing point, then we just update that point
                        points = d.automation.volume.points
                        
                        #  TODO : factor out and put automated tests on this logic
                        if points.length and timeOffset > points.slice(-1)[0][0]
                            points.push([timeOffset, d.volume])
                            return

                        index = 0
                        
                        while points[index][0] < timeOffset
                            index++

                        diff = points[index][0] - timeOffset
                        replace = diff < 0.01

                        if not replace and index > 0
                            if timeOffset - points[index-1][0] < 0.01
                                index--
                                replace = true

                        if replace
                            points[index][1] = d.volume
                        else
                            points.splice(index, 0, [timeOffset, d.volume])


            lastChange = null
            d.on 'change', =>
                if lastChange and (new Date() - lastChange) < 10
                    return
                lastChange = new Date()
                if d.dragging
                    setVolumeAndPan()

            play = ->
                audioOut = sequence.audioOut()
                if (!audioOut || !d._buffer) then return
                audioContext = AudioContext()
                source = audioContext.createBufferSource()
                source.buffer = d._buffer
                
                gain = audioContext.createGain()
                panner = audioContext.createStereoPanner()

                source.connect(gain)
                gain.connect(panner)
                panner.connect(audioOut)

                timeOffset = sequence.currentTime() - (d.startTime || 0)

                whenToStart = if timeOffset < 0 then audioContext.currentTime - timeOffset else 0
                offset = if timeOffset > 0 then timeOffset else 0
                source.start(whenToStart, offset)

                d._gain = gain
                d._panner = panner
                d._source = source

                if d._timeouts
                    d._timeouts.forEach (to) =>
                        clearTimeout(to)

                d._timeouts = []
                
                if d.automation and d.automation.volume
                    p = lastVolumePointBeforeNow()
                    d.volume = p[1]
                    points = d.automation.volume.points
                    futurePoints = points.filter (p) => p[0] > timeOffset
                    futurePoints.forEach (p, i) =>
                        diff = p[0] - timeOffset
                        changeSlider = =>
                            if !d.dragging
                                d.volume = p[1]
                                setVolumeAndPan()
                            else
                                index = points.indexOf(p)
                                points.splice(index, 1)

                        d._timeouts.push(setTimeout(changeSlider, diff * 1000))

                setVolumeAndPan()

            sequence.on 'play.audio' + _uid, =>
                playing = true
                play()

            sequence.on 'timeselect.audio' + _uid, =>
                if d.automation and d.automation.volume
                    d.volume = lastVolumePointBeforeNow()[1]
            
            stop = =>
                playing = false
                if not ('_source' of d)
                    console.log('stopping but no source set')
                if d._source
                    d._source.stop(0)
                if d._gain
                    d._gain.gain.cancelScheduledValues(0)
                if d._timeouts
                    d._timeouts.forEach (to) =>
                        clearTimeout(to)
                delete d._source

            sequence.on('stop.audio' + _uid, stop)
                
            sequence.on 'loop.audio' + _uid, (start) ->
                if d._source
                    d._source.stop(0)
                if playing
                    play()

            d.on 'change', () =>
                svg.classed('over', d.over)
                if (d.dead)
                    stop()
                    sequence.on('play.audio' + _uid, null)
                    sequence.on('timeselect.audio' + _uid, null)
                    sequence.on('stop.audio' + _uid, null)
                    sequence.on('loop.audio' + _uid, null)


    audio.redraw = (selection, options) ->
        if options and options.addOnsets
            selection.each (d,i) ->
                onsets = Onsets()
                    .x(x)
                    .timeline(sequence.timeline())
                    #.onsetTimes(d.onsetTimes)

                svg = d3.select(this).select('svg')
                svg.call(onsets)
    

    audio.on = (type, listener) ->
        dispatch.on(type, listener)
        return audio


    return d3.rebind(audio, commonProperties(), 'sequence','height')