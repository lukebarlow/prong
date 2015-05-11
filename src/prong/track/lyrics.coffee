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

    lyrics = (selection, options) ->

        sequence = lyrics.sequence()
        selection.append('div')
            .attr('class','trackName')
            .append('span')
            .text(prong.trackName) 
        
        height = selection.datum().height || sequence.trackHeight() || 128
        display = selection.append('div')
            .style('height', height + 'px')
            .style('width', sequence.width() + 'px') 
        display.classed('lyrics', true)

        uid = prong.uid()
        data = selection.datum().data
        timer = null
        i = null

        showLyric = -> display.text(data[i].text)

        setTimerForNextLyric = ->
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

        sequence.on 'play.lyrics' + uid, play
        sequence.on 'stop.lyrics' + uid, stop
        sequence.on 'loop.lyrics' + uid, (start) ->
            stop()
            play()
            
        sequence.timeline().on 'timeselect.lyrics' + uid, (time) ->
            i = lyricIndexAtTime(data, time)
            showLyric()
        

    lyrics.on = (type, listener) ->
        dispatch.on(type, listener)
        return lyrics


    return d3.rebind(lyrics, commonProperties(), 'sequence','height')

