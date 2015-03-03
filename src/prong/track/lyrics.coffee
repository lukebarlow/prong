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
        display = selection.append('div').style('height', height + 'px')    
        #selection.text(' ');
        display.classed('lyrics', true)

        uid = prong.uid()
        data = selection.datum().data
        timeouts = []


        sequence.on 'play.lyrics' + uid, ->
            currentTime = sequence.currentTime()
            # find the position of the first lyric to show
            i = lyricIndexAtTime(data, currentTime)
            display.text(data[i].text)
            for d in data.slice(i+1)
                after = ->
                    display.text(d.text)
                timeouts.push(setTimeout(after, 1000 * (d.time - currentTime)))


        sequence.on 'stop.lyrics' + uid, ->
            timeouts.map(clearTimeout)

        # sequence.on('scrub.lyrics' + uid, ->
        #     console.log('scrubbibg')

        sequence.timeline().on 'timeselect.lyrics' + uid, (time) ->
            i = lyricIndexAtTime(data, time)
            display.text(data[i].text)
        

    lyrics.on = (type, listener) ->
        dispatch.on(type, listener)
        return lyrics


    return d3.rebind(lyrics, commonProperties(), 'sequence','height')

