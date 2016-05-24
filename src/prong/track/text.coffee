d3 = require('d3-prong')
commonProperties = require('../commonProperties')
trackName = require('../trackName')
Uid = require('../uid')
TrackHeader = require('./trackHeader')

module.exports = ->

    sequence = null
    height = null
    dispatch = d3.dispatch('load')

    #returns the index in the data array for the lyric which
    #should be shown at the specified time
    lyricIndexAtTime = (data, time) ->
        i = 0
        for row, _i in data
            i = _i
            if data[i].time > time then break
        if i > 0 then i--
        return i

    text = (selection, options) ->

        sequence = text.sequence()

        selection.append('g')
            .call(TrackHeader().sequence(sequence))
        
        height = selection.datum().height || sequence.trackHeight() || 128
        
        display = selection.append('text')
            .attr('x', sequence.width() / 2)
            .attr('y', (d) => d.height / 2)
            .attr('width', sequence.width())
            .attr('height', (d) => d.height)
            .attr('text-anchor', 'middle')
            .attr('alignment-baseline', 'middle')
            .text('')

        display.classed('textTrack', true)

        uid = Uid()
        data = selection.datum().data or []
        timer = null
        i = null

        showLyric = -> 
            data = selection.datum().data or []
            display.text(data[i] and data[i].text or '')

        setTimerForNextLyric = ->
            if timer
                clearTimeout(timer)
            hasNextLyric = data.length > (i + 1)
            if hasNextLyric
                nextLyric = data[i + 1]
                currentTime = sequence.currentTime()
                delay = (nextLyric.time - currentTime) * 1000
                after = ->
                    i++
                    showLyric()
                    setTimerForNextLyric()
                timer = setTimeout(after, delay)

        play = ->
            currentTime = sequence.currentTime()
            i = lyricIndexAtTime(data, currentTime)
            showLyric()
            setTimerForNextLyric()

        stop = ->
            if timer
                clearTimeout(timer)

        sequence.on 'play.text' + uid, play
        sequence.on 'stop.text' + uid, stop
        sequence.on 'loop.text' + uid, (start) ->
            stop()
            play()
            
        sequence.timeline().on 'timeselect.text' + uid, (time) ->
            i = lyricIndexAtTime(data, time)
            showLyric()

        selection.each (d) ->
            if d._loader
                loadingMessage = d3.select(this).append('text')
                    .attr('class','trackLoading')
                    .attr('x', 20)
                    .attr('y', (d) => d.height / 2)
                    .attr('alignment-baseline', 'middle')
                d._loader loadingMessage, ->
                    loadingMessage.remove()
                    i = lyricIndexAtTime(data, sequence.currentTime())
                    showLyric()
                    console.log('loaded')

        
    text.on = (type, listener) ->
        dispatch.on(type, listener)
        return text


    return d3.rebind(text, commonProperties(), 'sequence','height')

