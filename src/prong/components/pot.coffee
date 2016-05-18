# A rotating circular tweakable knob, like a pan or fx control 

d3 = require('d3-prong')
omniscience = require('omniscience')

module.exports = ->

    dragging = false
    radius = 20
    outerRadius = radius + 12
    angle = Math.PI * 0.64
    scale = d3.scale.linear().range([-angle, angle]).clamp(true)
    format = d3.format('f')
    dispatch = d3.dispatch('change','end')
    prefix = ''
    title = ''
    key = null


    pot = (selection) ->

        textYOffset = radius / 4
        if radius == 0
            outerRadius = radius + 20
            textYOffset = 18

        dragstart = (d) ->
            selection.filter((_d) => _d == d)
                .classed('dragging', true)
            d.dragging = dragging = true
            d3.event.sourceEvent.stopPropagation()

        dragend = (d) ->
            selection.filter((_d) => _d == d)
                .classed('dragging', false)
            d.dragging = dragging = false
            d3.event.sourceEvent.stopPropagation()

        dragmove = (d, i) ->
            d[key] -= d3.event.dy
            min = scale.domain()[0]
            max = scale.domain()[1]
            if (d[key] > max) then d[key] = max
            if (d[key] < min) then d[key] = min
            redraw()
            dispatch.change(d, i, key)

        selection.attr('class','pot')

        drag = d3.behavior.drag()
            .on('dragstart',dragstart)
            .on('drag',dragmove)
            .on('dragend',dragend)

        backgroundArc = d3.svg.arc()
            .outerRadius(outerRadius)
            .innerRadius(radius)
            .startAngle(-angle)
            .endAngle(angle)

        arc = d3.svg.arc()
            .outerRadius(outerRadius)
            .innerRadius(radius)
            .startAngle (d) ->
                value = d[key]
                return scale(if value < 0 then value else 0)
            .endAngle (d) ->
                value = d[key]
                return scale(if value > 0 then value else 0)

        setupEvents = (selection) ->
            selection.call(drag)
                .on 'dblclick', (d) ->
                    d[key] = 0
                    redraw()

        selection.call(setupEvents)

        selection.append('circle')
            .attr('r', radius)

        selection.append('path')
            .attr('class', 'background')
            .attr('d', backgroundArc)

        selection.append('path')
            .attr('class', 'arc pan')
            .attr('d', arc)

        selection.append('text')
            .attr('text-anchor','middle')
            .attr('transform', "translate(0,#{textYOffset})")
            .text( (d) -> d[key] )

        # use the Object.watch feature to listen for changes to the datum
        # and redraw
        selection.each (d) ->
            d.on 'change.pot', =>
                redraw(d)

        redraw = (d) ->
            selection.selectAll('.arc').attr('d', arc)
            selection.selectAll('text').text( (d) -> d[key] )


    # getter/setter for the domain of the pot. i.e. the range of
    #  values it slides over. This should be be a two element array.

    #   e.g. [0,100] makes a pot which slides between values 0 and 100
    
    pot.domain = (_domain) ->
        if not arguments.length then return scale.domain()
        scale.domain(_domain)
        return pot

    # getter/setter for width
    pot.radius = (_radius) ->
        if not arguments.length then return radius
        radius = _radius
        return pot

    # getter/setter for format
    pot.format = (_format) ->
        if not arguments.length then return format
        format = _format
        return pot


    # for attaching event listeners
    pot.on = (type, listener) ->
        dispatch.on(type, listener)
        return pot


    pot.key = (_key) ->
        if not arguments.length then return key
        key = _key
        return pot


    return pot