commonProperties = require('../commonProperties')
uid = require('../uid')
d3 = require('d3-prong')

module.exports = () ->
    
    musicalTime = null
    selection = null

    updateMinorLines = (x) ->
        ticks = getTicks()
        minorLines = selection.selectAll('line.minor').data(ticks, (d) -> d)
        minorLines.attr('x1', x).attr('x2', x);
        minorLines.enter()
            .append('line')
            .attr('class', 'minor')
            .attr('y1', 0)
            .attr('y2', 10)
            .attr('x1', x)
            .attr('x2', x);
        minorLines.exit().remove()


    getTicks = ->
        ticks = []
        musicalTime.bars.forEach (chunk) ->
            ticks = ticks.concat(d3.range(chunk.startBarNumber, chunk.startBarNumber + chunk.numberOfBars, 1 / chunk.numerator))
        return ticks


    musicalTimeline = (_selection) ->
        selection = _selection
        selection.classed('musicalTimeline',true)
        timeline = musicalTimeline.timeline()

        getX = ->
            return musicalTime.barsToPixels(timeline.x())

        x = getX()
        ticks = d3.range(1,musicalTime.finalBarNumber + 2)

        tickFormat = (tick) ->
            if tick < musicalTime.finalBarNumber + 1
                return d3.format('n')(tick)
            return ''

        axis = d3.svg.axis()
            .scale(x)
            .tickSize(10,5,0)
            .tickValues(ticks)
            .tickFormat(tickFormat)

        updateMinorLines(x, selection)
        selection
            .attr('width',timeline.width())
            .call(axis)
            .style('cursor','pointer')
            .on 'click', ->
                sequence = musicalTimeline.timeline().sequence()
                startTime = musicalTime.bars[0].startTime
                endTime = musicalTime.endTime
                sequence.play(startTime, endTime, true)

        redraw = () ->
            x = getX()
            updateMinorLines(x)
            selection.call(axis.scale(x))

        _uid = uid()

        timeline.on 'change.musicalTimeline' + _uid, ->
            redraw()

        musicalTimeline.destroy = () ->
            timeline.on 'change.musicalTimeline' + _uid, null

        return musicalTimeline


    musicalTimeline.musicalTime = (_musicalTime) ->
        if not arguments.length then return musicalTime
        musicalTime = _musicalTime
        return musicalTimeline

    return d3.rebind(musicalTimeline, commonProperties(), 'timeline')