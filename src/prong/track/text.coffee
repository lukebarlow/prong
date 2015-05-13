d3 = require('../d3-prong-min')
commonProperties = require('../commonProperties')

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
        selection.append('div')
            .attr('class','trackName')
            .append('span')
            .text(prong.trackName) 
        
        height = selection.datum().height || sequence.trackHeight() || 128
        display = selection.append('div')
            .style('height', height + 'px')
            .style('width', sequence.width() + 'px') 
        display.classed('textTrack', true)

        uid = prong.uid()
        data = selection.datum().data
        timer = null
        i = null

        showLyric = -> display.text(data[i].text)

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
        

    text.on = (type, listener) ->
        dispatch.on(type, listener)
        return text


    return d3.rebind(text, commonProperties(), 'sequence','height')

