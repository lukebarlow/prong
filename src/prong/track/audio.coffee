d3 = require('../d3-prong-min')
commonProperties = require('../commonProperties')
sound = require('../sound').sound
Waveform = require('../components/waveform')
Onsets = require('../components/onsets')
prong = require('../')
#Lines = require('../components/lines')
#Note = require('../components/note')

# audioTrack is responsible for drawing out the audio tracks. This is a
# container for different representations of audio (waveform and/or spectrogram)
module.exports = ->

    width = null
    dispatch = d3.dispatch('load')

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

            div.append('div').attr('class','trackName').append('span').text(prong.trackName)
            loadingMessage = div.append('span').attr('class','trackLoading')

            svg = div.append('svg')
                .attr('height',height)
                .attr('width', '100%')
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

                svg.call(waveform)
                dispatch.load(d)

            uid = prong.uid()
            playing = false

            play = ->
                audioOut = sequence.audioOut()
                if (!audioOut || !d._buffer) then return
                audioContext = prong.audioContext()
                source = audioContext.createBufferSource()
                source.buffer = d._buffer
                
                gain = audioContext.createGain()
                panner = audioContext.createPanner()

                # volume
                setVolume = ->
                    gain.gain.value = d.volume / 100.0
                d.watch( 'volume', -> setVolume() )
                setVolume()

                # pan
                setPan = ->
                    # pan numbers are between -64 and +63. We convert this
                    # into an angle in radians, and then into an x,y position
                    angle = d.pan / 64 * Math.PI * 0.5
                    x = Math.sin(angle) / 2
                    y = Math.cos(angle) / 2
                    panner.setPosition(x, y, 0)
                d.watch('pan', -> setPan() )
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

            sequence.on 'play.audio' + uid, ->
                playing = true
                play()
            
            sequence.on 'stop.audio' + uid, ->
                playing = false
                if not ('source' of d)
                    console.log('stopping but no source set')
                if (d.source)
                    d.source.stop(0)
                delete d.source

            sequence.on 'loop.audio' + uid, (start) ->
                if d.source
                    d.source.stop(0)
                if playing
                    play()

            sequence.on 'volumeChange.audio'+uid, ->
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


