d3 = require('d3-prong')
omniscience = require('omniscience')

module.exports = ->

    dragging = false
    width = 40
    height = 100
    horizontal = false
    scale = d3.scale.pow().exponent(1).range([0,height]).clamp(true)
    format = d3.format('.2f')
    dispatch = d3.dispatch('change')
    prefix = ''
    title = ''
    key = null
    padding = 1
    value = null
    circleStyle = false # circle style means the slider is drawn differently

    dragstart = (d) ->
        d.dragging = dragging = true
        d3.event.sourceEvent.stopPropagation()


    dragend = (d) ->
        d.dragging = dragging = false
        d3.event.sourceEvent.stopPropagation()


    slider = (selection) ->

        getText = (d) -> 
            if key
                prefix + format(d[key])
            else
                prefix + format(value)

        dragmove = (d, i) ->
            if !dragging then return

            position = if horizontal then d3.event.x else d3.event.y
            _value = scale.invert(position) 
            
            last = if key then d[key] else value
            if last == _value then return

            if key
                d[key] = _value
            else
                value = _value
                
            redraw()
            if key
                dispatch.change(d, i, key)
            else
                dispatch.change(value)
            d3.event.sourceEvent.stopPropagation()

        g = selection

        g.classed('slider', true)

        drag = d3.behavior.drag()
            .on('dragstart',dragstart)
            .on('drag',dragmove)
            .on('dragend',dragend)

        circle = null
        text = null
        background = null

        height = Math.abs(scale.range()[0] - scale.range()[1])

        position = (d) ->
            if key
                scale(d[key]) 
            else 
                scale(value)

        cy = (d) -> position(d) + 1

        backgroundLength = (d) -> 
            if horizontal
                position(d) + circleStyle * width + 1
            else
                Math.abs(scale(0) - position(d)) + circleStyle * (width - padding * 2)

        verticalBackgroundY = (d) -> 
            p = Math.min(position(d), scale(0))
            return p  - (circleStyle * width / 2) + 1
            
        verticalTextY = (d) -> position(d) + 3

        rounding = (selection) ->
            if circleStyle
                selection
                    .attr('rx',width / 2)
                    .attr('ry',width / 2)

        draggerDisplay = (selection) ->
            if not circleStyle
                selection.style('opacity','0')

        if horizontal
            g.append('rect')
                .attr('y', 0)
                .attr('x', scale.range()[0] - circleStyle * width / 2)
                .attr('height', width)
                .attr('width', height + circleStyle * width)
                .call(rounding)

            background = g.append('rect')
                .attr('class','background')
                .attr('x', 0 - circleStyle * width / 2)
                .attr('y', padding)
                .attr('height', width - padding * 2)
                .attr('width', (d) -> backgroundLength(d) - 1)
                .call(rounding)

            circle = g.append('circle')
                .attr('cy', width / 2)
                .attr('cx', (d) -> position(d) - 1)
                .attr('r', width / 2)
                .style('cursor', 'pointer')
                .attr('fill', 'white')
                .call(drag)
                .call(draggerDisplay)

            text = g.append('text')
                .attr('x', (d) -> position(d) - 1)
                .attr('y', width / 2 + 2)
                .attr('text-anchor', 'middle')
                .attr('alignment-baseline','middle')
                .attr('cursor', 'pointer')
                .text(getText)
                .call(drag)
        else
            g.append('rect')
                .attr('x', 0)
                .attr('y', scale.range()[1] - circleStyle * width / 2)
                .attr('height',height + circleStyle * width)
                .attr('width', width)
                .call(rounding)

            background = g.append('rect')
                .attr('class','background')
                .attr('x', padding)
                .attr('y', verticalBackgroundY)
                .attr('height', backgroundLength)
                .attr('width', width - padding * 2)
                .call(rounding)

            circle = g.append('circle')
                .attr('cx', width / 2 )
                .attr('cy', cy)
                .attr('r', width / 2)
                .style('cursor','pointer')
                .attr('fill','white')
                .call(drag)
                .call(draggerDisplay)

            text = g.append('text')
                .attr('x',width / 2)
                .attr('y', verticalTextY)
                .attr('text-anchor','middle')
                .attr('alignment-baseline','middle')
                .attr('cursor','pointer')
                .text(getText)
                .call(drag)

        if key
            selection.each (d) ->
                d.on 'change', =>
                    redraw(d)
                    
        
        redraw = (d) ->
            if (horizontal)
                circle.attr('cx', (d) -> position(d) - 1)
                text.attr('x', (d) -> position(d) - 1)
                    .text(getText)
                background
                    .attr('width', (d) -> backgroundLength(d) - 1)
            else
                circle.attr('cy', cy)
                text.attr('y', verticalTextY )
                    .text(getText)
                background
                    .attr('y', verticalBackgroundY)
                    .attr('height', backgroundLength)


    slider.domain = (_domain) ->
        if not arguments.length then return scale.domain()
        scale.domain(_domain)
        return slider


    slider.exponent = (_exponent) ->
        if not arguments.length then return scale.exponent()
        scale.exponent(_exponent)
        return slider


    slider.height = (_height) ->
        if not arguments.length then return height
        height = _height
        if (horizontal)
            scale.range([0,height])
        else
            scale.range([height,0])
        return slider


    slider.width = (_width) ->
        if not arguments.length then return width
        width = _width
        return slider


    slider.format = (_format) ->
        if not arguments.length then return format
        format = _format
        return slider


    slider.prefix = (_prefix) ->
        if not arguments.length then return prefix
        prefix = _prefix
        return slider
    

    slider.horizontal = (_horizontal) ->
        if not arguments.length then return horizontal
        if _horizontal and not horizontal
            #flip the range
            range = scale.range()
            scale.range([range[1],range[0]])
        horizontal = _horizontal
        return slider


    slider.on = (type, listener) ->
        dispatch.on(type, listener)
        return slider


    slider.key = (_key) ->
        if not arguments.length then return key
        key = _key
        return slider


    slider.title = (_title) ->
        if not arguments.length then return title
        title = _title
        return slider


    slider.value = (_value) ->
        if not arguments.length then return value
        value = _value
        return slider


    slider.circleStyle = (_circleStyle) ->
        if not arguments.length then return circleStyle
        circleStyle = _circleStyle
        return slider


    slider.dragging = ->
        return dragging


    return slider


