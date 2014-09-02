commonProperties = require('../commonProperties')
uid = require('../uid')
timeline = require('./timeline')
d3 = require('d3')


module.exports = ->

    data = {startTime : 0, bars: []}
    selection = null

    fleshOutData = ->
        tempo = null
        lastDenominator = 4 # defaults to the most common
        time = data.startTime
        barNumber = 1
        data.bars.forEach (chunk) ->
            if not ('tempo' of chunk)
                if not tempo
                    throw 'Must specify tempo for the first chunk'
                chunk.tempo = tempo * chunk.denominator / lastDenominator
            tempo = chunk.tempo
            lastDenominator = chunk.denominator
            chunk.startTime = time
            time += chunk.numerator * chunk.numberOfBars * 60 / chunk.tempo
            chunk.startBarNumber = barNumber
            barNumber += chunk.numberOfBars

        data.finalBarNumber = barNumber - 1
        data.endTime = time


    getTicks = ->
        ticks = []
        data.bars.forEach (chunk) ->
            ticks = ticks.concat(d3.range(chunk.startBarNumber, chunk.startBarNumber + chunk.numberOfBars, 1 / chunk.numerator))
        return ticks


    updateMinorLines = (x) ->
        ticks = getTicks()
        minorLines = selection.selectAll('line.minor').data(ticks, (d) -> d)
        minorLines.attr('x1', x).attr('x2', x);
        minorLines.enter()
            .append('line')
            .attr('class', 'minor')
            .attr('y1', 0)
            .attr('y2', 200)
            .attr('x1', x)
            .attr('x2', x);
        minorLines.exit().remove()


    musicalTimeline = (_selection) ->
        selection = _selection
        selection.classed('musicalTimeline',true)

        getX = () ->
            timeToPixels = musicalTimeline.timeline().x() # converts time in seconds to pixels
            domain = (data.bars.map (chunk) -> chunk.startBarNumber)
            domain.push(data.finalBarNumber + 1)
            range = data.bars.map (chunk) -> timeToPixels(chunk.startTime)
            range.push(timeToPixels(data.endTime))
            x = d3.scale.linear()
                .domain(domain)
                .range(range)
            return x

        x = getX()
        ticks = d3.range(1,data.finalBarNumber + 2)

        tickFormat = (tick) ->
            if tick < data.finalBarNumber + 1
                return d3.format('n')(tick)
            return ''

        axis = d3.svg.axis()
            .scale(x)
            .tickSize(20,5,0)
            .tickValues(ticks)
            .tickFormat(tickFormat)

        updateMinorLines(x, selection)
        selection
            .attr('width',musicalTimeline.timeline().width())
            .call(axis)

        redraw = () ->
            x = getX()
            updateMinorLines(x)
            selection.call(axis.scale(x))
            
        _uid = uid()

        musicalTimeline.timeline().on 'change.' + _uid, ->
            redraw()

        musicalTimeline.destroy = () ->
            musicalTimeline.timeline().on 'change.' + _uid, null


    musicalTimeline.data = (_data) ->
        if not arguments.length then return data
        data = _data
        fleshOutData()
        return musicalTimeline


    d3.rebind(musicalTimeline, commonProperties(), 'timeline')
    return d3.rebind(musicalTimeline, timeline(), 'height')