commonProperties = require('../commonProperties')
preparePcmData = require('./preparePcmData')
uid = require('../uid')
d3 = require('d3-prong')
keysort = require('../keysort')
omniscience = require('../omniscience')


module.exports = ->

    key = null
    dispatch = d3.dispatch('changing', 'change')

    automation = ->

        selection = this
        x = automation.timeline().x()
        width = automation.width()

        y = d3.scale.linear()
            .range([automation.height() - 5, 5])
            .domain([0, 100])
            #.clamp(true)

        lineX = (d) -> x(d[0])
        lineY = (d) -> y(d[1])

        line = d3.svg.line()
            .x(lineX)
            .y(lineY)

        selection.classed('automation', true)

        dragstart = ->
            d3.event.sourceEvent.stopPropagation()

        dragmove = (e) ->
            d3.event.sourceEvent.stopPropagation()
            dx = (x.invert(d3.event.dx) - x.invert(0))
            dy = (y.invert(d3.event.dy) - y.invert(0))
            e[0] += dx
            e[1] += dy
            update()

            # TODO : if you drag past it in time, then switch the order
            #originalArray = d.automation.volume
            #originalArray.sort(keysort(0))
            dispatch.changing()

        dragend = ->
            d3.event.sourceEvent.stopPropagation()
            dispatch.change()

        # this is the behavior for dragging points around. It is not used
        # when the points are not exposed
        drag = d3.behavior.drag()
            .on('dragstart', dragstart)
            .on('drag', dragmove)
            .on('dragend', dragend)

        path = selection.append('path')

        circleContainer = selection.append('g')
        
        update = =>
            path.attr 'd', (d) =>
                # sort the points in time to keep the line coherent
                d[key].points.sort(keysort(0))

                line.interpolate(d[key].interpolate)
                line(d[key].points)

            circleJoin = circleContainer
                .filter((d) => d[key].interpolate == 'linear')
                .selectAll('circle')
                .data((d) => d[key].points)                
                
            circleJoin.attr('cx', lineX).attr('cy', lineY)

            circleJoin.enter()
                .append('circle')
                .attr('cx', lineX)
                .attr('cy', lineY)
                .attr('r', 5)
                .call(drag)

            circleJoin.exit().remove()

        update()

        selection.each (d) ->
            omniscience.watch(d, update)
            
        automation.timeline().on("change.#{uid()}", update)


    automation.on = (type, listener) ->
        dispatch.on(type, listener)
        return automation


    automation.key = (_key) ->
        if not arguments.length then return key
        key = _key
        return automation


    return d3.rebind(automation, commonProperties(), 'width', 'height', 
            'timeline')

