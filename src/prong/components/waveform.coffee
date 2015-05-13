commonProperties = require('../commonProperties')
preparePcmData = require('./preparePcmData')
uid = require('../uid')
d3 = require('../d3-prong-min')


DISPLAY_ABOVE_AND_BELOW_CUTOFF = 10
DISPLAY_AS_LINE_CUTOFF = 1


domainWidth =  (domain) ->
    return domain[1] - domain[0]


module.exports = ->

    verticalZoom = 1

    waveform = ->

        selection = this
        x = waveform.x()
        width = waveform.width()

        y = d3.scale.linear()
            .range([waveform.height(),0])
            .domain([1 / verticalZoom,-1 / verticalZoom])

        roundedY = (d) ->
            d3.round(y(d), 1)

        # draws part of the waveform (this is called multiple times if there
        # are sections before, inside, and after the looped section)
        drawSection = (container, data, sampleX, offset, samplesPerPixel, cls) ->
            g = container.append('g')
            if cls
                g.classed(cls, true)

            # then draw
            #if samplesPerPixel > DISPLAY_AS_LINE_CUTOFF
            area = d3.svg.area()
                .x (_, i) -> 
                    ret = d3.round(sampleX(i + offset), 1)
                    #console.log('x', ret)
                    return ret

            if samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF
                area.y0((d) -> roundedY(-Math.abs(d)))
                    .y1((d) -> roundedY(Math.abs(d)))
            else
                area.y0(roundedY(0))
                    .y1(roundedY)

            g.classed('area','true')
                .append('path')
                .datum(data)
                .attr('d', area)

            # else
            #     line = d3.svg.line()
            #         .x((_, i) ->
            #             ret = sampleX(i)
            #             return d3.round(ret, 1)
            #         )
            #         .y( (d) -> y(d) ) # TODO. just y
            #         .interpolate('linear')

            #     g.classed('line','true')
            #         .append('path')
            #         .datum(data)
            #         .attr('d', line);


        drawSections = (x, sections) ->
            selection.each (d) ->
                container = d3.select(this)

                # clear out any previously drawn waveform
                container.selectAll('.area').remove()
                container.selectAll('.line').remove()

                [data, sampleX, samplesPerPixel] = preparePcmData(d, x)

                if data
                    lastE = null
                    for section in sections
                        [s, e] = section.domain.map(x).map(sampleX.invert)
                        if e < 0 then continue
                        s = Math.max(0, s)
                        s = if lastE then lastE - 1 else Math.floor(s)
                        e = lastE = Math.ceil(e)
                        subdata = data.slice(s, e)
                        drawSection(container, subdata, sampleX, s, 
                                samplesPerPixel, section.class)


        draw = ->
            #console.log('calling draw')
            if (timeline = waveform.timeline()) and (not timeline.loopDisabled())
                [loopStart, loopEnd] = waveform.timeline().loop()
            else
                [loopStart, loopEnd] = [null, null]
            [start, end] = x.domain()

            if loopStart is null or loopEnd is null or loopEnd <= start or loopStart >= end
                # no loop in view
                drawSections(x, [{domain : [start, end]}])
            else
                # start is in view
                if loopStart > start and loopStart < end
                    # end is also in view
                    if loopEnd < end and loopEnd > start
                        drawSections(x, [
                            { domain: [start, loopStart] },
                            { domain: [loopStart, loopEnd], class: 'loop'}
                            { domain: [loopEnd, end]}
                        ])
                    else
                        drawSections(x, [
                            { domain: [start, loopStart] },
                            { domain: [loopStart, end], class: 'loop'}
                        ])
                else # start is not in view
                    if loopEnd < end and loopEnd > start # end is in view
                        drawSections(x, [
                            { domain: [start, loopEnd], class: 'loop' },
                            { domain: [loopEnd, end]}
                        ])
                    else
                        drawSections(x, [
                            { domain: [start, end], class: 'loop' },
                        ])


        draw()
        timeline = waveform.timeline()
        if timeline
            # this timing logic tries to keep waveform redrawing as smooth
            # as possible. It times how long it takes to redraw the waveform
            # and makes sure not to redraw more frequently than that

            lastTimeout = null
            drawingTime = null
            lastDrawingStart = null

            drawAndTime = ->
                start = new Date()
                draw()
                drawingTime = new Date() - start
            
            timeline.on 'change.' + uid(), ->
                if (lastTimeout) then clearTimeout(lastTimeout)
                if (not lastDrawingStart) or (new Date() - lastDrawingStart) > (drawingTime * 2)
                    drawAndTime()
                else
                    after = ->
                        drawAndTime()
                        lastTimeout = null
                    lastTimeout = setTimeout(after, 50)

            timeline.on 'loopChanging.' + uid(), draw
            timeline.on 'loopChange.' + uid(), draw


    # getter/setter for vertical zoom
    waveform.verticalZoom = (_verticalZoom) ->
        if not arguments.length then return verticalZoom;
        verticalZoom = _verticalZoom
        return waveform


    # inherit properties from the commonProperties
    return d3.rebind(waveform, commonProperties(), 'x', 'width', 'height', 
            'timeline')