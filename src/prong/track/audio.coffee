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
#Lines = require('../components/lines')
#Note = require('../components/note')

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
                .each (d) ->
                    d.watch 'over', (property, oldValue, newValue) ->
                        #console.log('audio over seen')
                        svg.classed('over', newValue)
                        return newValue

            middleground = svg.append('g').attr('class', 'middleground')
            foreground = svg.append('g').attr('class', 'foreground')
  
            src = d.audioSrc || d.src

            # each track has a 'loader' method which is responsible for
            # asynchronously loading and decoding the data, and reporting
            # on progress as it goes. The default one loads from http. Once
            # the loader is complete, the track should have channel and
            # buffer properties
            if not ('_loader' of d)
                if '_channel' of d
                    # if we already have a channel set, set a 'do nothing' loader
                    d._loader = (_,callback) -> callback()
                else
                    d._loader = httpSoundLoader

            d._loader loadingMessage, ->
                loadingMessage.remove()
                waveform = Waveform()
                    .x(x)
                    .height(height)
                    .verticalZoom(sequence.waveformVerticalZoom())
                    .timeline(sequence.timeline())

                middleground.call(waveform)

                if d.automation
                    automation = Automation()
                        .x(x)
                        .height(height)
                        .timeline(sequence.timeline())
                        .on 'change', () => 
                            console.log('automation change')
                            dispatch.automationChange()

                    foreground.call(automation)

                dispatch.load(d)

            
            _uid = uid()
            playing = false

            play = ->
                audioOut = sequence.audioOut()
                if (!audioOut || !d._buffer) then return
                audioContext = AudioContext()
                source = audioContext.createBufferSource()
                source.buffer = d._buffer
                
                gain = audioContext.createGain()
                panner = audioContext.createStereoPanner()

                # volume
                setVolume = ->
                    gain.gain.value = d.volume / 100.0

                d.watch 'volume', (property, oldValue, newValue) ->
                    setVolume()
                    return newValue

                setVolume()

                # pan
                setPan = ->
                    panner.pan.value = d.pan / 64

                d.watch 'pan', (property, oldValue, newValue) ->
                    setPan()
                    return newValue

                setPan()

                source.connect(gain)
                gain.connect(panner)
                panner.connect(audioOut)

                timeOffset = sequence.currentTime() - (d.startTime || 0)

                whenToStart = if timeOffset < 0 then audioContext.currentTime - timeOffset else 0
                offset = if timeOffset > 0 then timeOffset else 0
                source.start(whenToStart, offset)
                d.gain = gain
                d.source = source

            sequence.on 'play.audio' + _uid, ->
                playing = true
                play()
            
            sequence.on 'stop.audio' + _uid, ->
                playing = false
                if not ('source' of d)
                    console.log('stopping but no source set')
                if (d.source)
                    d.source.stop(0)
                delete d.source

            sequence.on 'loop.audio' + _uid, (start) ->
                if d.source
                    d.source.stop(0)
                if playing
                    play()

            sequence.on 'volumeChange.audio'+ _uid, ->
                console.log('IS THIS VOLUME CHANGE EVENT USED (or necessary)?')
                d.gain.gain.value = d.volume / 100.0


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


