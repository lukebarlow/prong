commonProperties = require('../commonProperties')
preparePcmData = require('./preparePcmData')
uid = require('../uid')
d3 = require('d3-prong')
keysort = require('../keysort')

entries = (object) =>
    Object.keys(object).map (key) =>
        [key, object[key]]


module.exports = ->

    dispatch = d3.dispatch('changing', 'change')

    automation = ->

        selection = this
        x = automation.x()
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

        selection.each (d) ->
            container = d3.select(this)
            
            automationEntries = entries(d.automation)

            g = container
                .selectAll('g.automation')
                .data(automationEntries)
                .enter()
                .append('g')
                #.attr('transform', 'translate(0, 20)')
                .attr('class', 'automation')

            path = g.append('path')
                .attr('d', ([name, data]) => line(data))


            path.on 'click', () =>
                

            circle = g.selectAll('circle')
                .data(([name, data]) => data)
                .enter()
                .append('circle')
                .attr('cx', lineX)
                .attr('cy', lineY)
                .attr('r', 5)
                
            dragstart = ->
                d3.event.sourceEvent.stopPropagation()

            dragmove = (e) ->
                d3.event.sourceEvent.stopPropagation()
                dx = (x.invert(d3.event.dx) - x.invert(0))
                dy = (y.invert(d3.event.dy) - y.invert(0))
                e[0] += dx
                e[1] += dy
                circle.attr('cx', lineX).attr('cy', lineY)
                path.attr('d', ([name, data]) => line(data))

                # TODO : if you drag past it in time, then switch the order
                originalArray = d.automation.volume
                originalArray.sort(keysort(0))
                dispatch.changing()

            dragend = ->
                d3.event.sourceEvent.stopPropagation()
                dispatch.change()

            drag = d3.behavior.drag()
                .on('dragstart', dragstart)
                .on('drag', dragmove)
                .on('dragend', dragend)

            circle.call(drag)

            
        automation.timeline().on "change.#{uid()}", =>

            x = automation.timeline().x()
            lineX = (d) -> x(d[0])
            selection.selectAll('g.automation circle')
                .attr('cx', lineX)
                .attr('cy', lineY)

            selection.selectAll('g.automation path')
                .attr('d', ([name, data]) => line(data))


    automation.on = (type, listener) ->
        dispatch.on(type, listener)
        return automation


    return d3.rebind(automation, commonProperties(), 'x', 'width', 'height', 
            'timeline')

