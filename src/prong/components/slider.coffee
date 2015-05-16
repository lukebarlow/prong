d3 = require('d3-prong')

module.exports = ->

    dragging = false
    width = 40
    height = 100
    horizontal = false
    scale = d3.scale.linear().range(0,height).clamp(true)
    format = d3.format('.2f')
    dispatch = d3.dispatch('change','end')
    prefix = ''
    title = ''
    key = null
    padding = 1


    dragstart = (e) ->
        dragging = true
        d3.event.sourceEvent.stopPropagation()


    dragend = (e) ->
        dragging = false
        d3.event.sourceEvent.stopPropagation()


    slider = (selection) ->
        if key is null then throw "Must set 'key' for slider"

        dragmove = (d, i) ->
            if !dragging then return
            d[key] = scale.invert(if horizontal then d3.event.x else d3.event.y)          
            text.text(prefix + format(d[key]))
            redraw()
            dispatch.change(d, i, key)
            d3.event.sourceEvent.stopPropagation()

        g = selection

        g.attr('class','slider')

        drag = d3.behavior.drag()
            .on('dragstart',dragstart)
            .on('drag',dragmove)
            .on('dragend',dragend)

        circle = null
        text = null
        background = null

        height = Math.abs(scale.range()[0] - scale.range()[1])

        position = (d) -> scale(d[key])

        text = (d) -> prefix + format(d[key])

        cy = (d) -> position(d) + 1
        backgroundLength = (d) -> 
            if horizontal
                position(d) + width
            else
                height - position(d) + width - padding * 2

        verticalBackgroundY = (d) -> position(d) - (width / 2) + 1
        verticalTextY = (d) -> position(d) + 3

        if horizontal
            g.append('rect')
                .attr('y', 0)
                .attr('x', scale.range()[0] - width / 2)
                .attr('height', width)
                .attr('width', height + width)
                .attr('rx', width / 2)
                .attr('ry', width / 2)

            background = g.append('rect')
                .attr('class','background')
                .attr('x', 0 - width / 2)
                .attr('y', padding)
                .attr('height', width - padding * 2)
                .attr('width', (d) -> backgroundLength(d) - 1)
                .attr('rx',width / 2)
                .attr('ry',width / 2)

            circle = g.append('circle')
                .attr('cy', width / 2)
                .attr('cx', (d) -> position(d) - 1)
                .attr('r', width / 2)
                .style('cursor', 'pointer')
                .attr('fill', 'white')
                .call(drag)

            text = g.append('text')
                .attr('x', (d) -> position(d) - 1)
                .attr('y', width / 2 + 2)
                .attr('text-anchor', 'middle')
                .attr('alignment-baseline','middle')
                .attr('cursor', 'pointer')
                .text(text)
                .call(drag)
        else
            g.append('rect')
                .attr('x', 0)
                .attr('y',scale.range()[1] - width / 2)
                .attr('height',height + width)
                .attr('width', width)
                .attr('rx', width / 2)
                .attr('ry', width / 2)

            background = g.append('rect')
                .attr('class','background')
                .attr('x', padding)
                .attr('y', verticalBackgroundY)
                .attr('height', backgroundLength)
                .attr('width', width - padding * 2)
                .attr('rx',width / 2)
                .attr('ry',width / 2)

            circle = g.append('circle')
                .attr('cx', width / 2 )
                .attr('cy', cy)
                .attr('r', width / 2)
                .style('cursor','pointer')
                .attr('fill','white')
                .call(drag)

            text = g.append('text')
                .attr('x',width / 2)
                .attr('y', verticalTextY)
                .attr('text-anchor','middle')
                .attr('alignment-baseline','middle')
                .attr('cursor','pointer')
                .text(text)
                .call(drag)


        selection.each (d) ->
            d.watch key, ->
                redraw(d)
        

        redraw = (d) ->
            if (horizontal)
                circle.attr('cx', (d) -> position(d) - 1)
                text.attr('x', (d) -> scale(d[key]) - 1)
                    .text( (d) -> prefix + format(d[key]))
                background
                    .attr('width', (d) -> backgroundLength(d) - 1)
            else
                circle.attr('cy', cy)
                text.attr('y', verticalTextY )
                    .text( (d) -> prefix + format(d[key]))
                background
                    .attr('y', verticalBackgroundY)
                    .attr('height', backgroundLength)


    slider.domain = (_domain) ->
        if not arguments.length then return scale.domain()
        scale.domain(_domain)
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


    return slider


