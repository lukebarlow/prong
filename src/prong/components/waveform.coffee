commonProperties = require('../commonProperties')
fx = require('../analysis/fx')
uid = require('../uid')
d3 = require('../d3-prong-min')

# component for drawing waveforms in an svg element
module.exports = ->

    startOffset = 0
    verticalZoom = 1

    # There are 3 slightly different ways of drawing the waveform, which depend
    # on the zoom level. These parameters are in units of 'samples per pixel'
    # and can be used to determine the switchover between drawing modes
    DISPLAY_ABOVE_AND_BELOW_CUTOFF = 10
    DISPLAY_AS_LINE_CUTOFF = 1
    WIDE_ZOOM = 5000
    MEDIUM_ZOOM = 1000


    waveform = ->
        selection = this
        draw = ->

            selection.each (d) ->
                sel = d3.select(this)
                d.startTime = d.startTime || 0

                ### there are essentially two scales at play
                    1. clipScale - this maps the sequence timeline
                    to the clip timeline. It can also be used to determine which
                    time slices of the channel are actually visible. The domain
                    and range will be shrunk to fit what's actually visible

                    2. sequenceScale - this maps the time of the sequence to the
                    pixels on the screen - the normal x scale. The domain is
                    sequence time and the range is pixels on screen.

                    by combining the two, we can map clip time to pixels
                ###

                d._buffer.sampleOffset = d._buffer.sampleOffset or 0

                x = waveform.x()
                domain = x.domain()
                range = x.range()
                channel = d._channel
                sampleRate = d._buffer.sampleRate
                startOffset = (d.startTime || 0)
                length = null

                d.clipStart = d.clipStart || 0
                d.clipEnd = d.clipEnd || (channel.length / sampleRate)

                length = d.clipEnd - d.clipStart
                clipDomain = [d.clipStart, d.clipEnd]
                clipRange = [d.startTime, d.startTime + length]
                clipScale = d3.scale.linear().range(clipRange).domain(clipDomain)
                clipStart = d.clipStart
                viewStart = clipStart + Math.max(domain[0] - d.startTime, 0)
                viewEnd = d.clipEnd - Math.max(d.startTime + length - domain[1], 0)

                # clear any previous areas and lines
                sel.selectAll('.area').remove()
                sel.selectAll('.line').remove()

                # if the waveform is out of view, then nothing more to do
                if (viewStart > viewEnd) then return

                width = waveform.width()
                height = waveform.height() || 128
                samplesPerPixel = Math.max(~~((Math.abs(domain[1] - domain[0]) * sampleRate) / width), 1)

                if not ('_cache' of d)
                    d._cache = {}
                
                data = null

                if not (WIDE_ZOOM of d._cache)
                    d._cache[WIDE_ZOOM] = fx.thinOut(channel, WIDE_ZOOM)

                if not (MEDIUM_ZOOM of d._cache)
                    d._cache[MEDIUM_ZOOM] = fx.thinOut(channel, MEDIUM_ZOOM)
                    
                sampleStart = (viewStart * sampleRate) + d._buffer.sampleOffset
                sampleEnd = (viewEnd * sampleRate) + d._buffer.sampleOffset
                # we cache the thinned data at two levels, so zooming is
                # faster
                if samplesPerPixel >= WIDE_ZOOM
                    samplesPerPixel = WIDE_ZOOM
                    data = d._cache[WIDE_ZOOM].slice(sampleStart / WIDE_ZOOM, sampleEnd / WIDE_ZOOM)
                else if (samplesPerPixel >= MEDIUM_ZOOM)
                    samplesPerPixel = MEDIUM_ZOOM
                    data = d._cache[MEDIUM_ZOOM].slice(sampleStart / MEDIUM_ZOOM, sampleEnd / MEDIUM_ZOOM)
                else
                    data = channel.subarray(sampleStart , sampleEnd)
                    data = fx.thinOut(data, samplesPerPixel, if samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF then 'max' else 'first')
                
                y = d3.scale.linear()
                    .range([height,0])
                    .domain([1 / verticalZoom,-1 / verticalZoom])

                translateX = 0

                sampleX = (d, i) ->
                    x(clipScale(i*samplesPerPixel/sampleRate + viewStart))
                

                # when zoomed out, we do it with an area...
                if samplesPerPixel > DISPLAY_AS_LINE_CUTOFF
                    area = d3.svg.area()
                        .x(sampleX)
                        .y0(if samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF then ( (d) -> y(-d)) else y(0) )
                        .y1(y)

                    sel.append('g')
                        .attr('class','area')
                        .attr('transform',"translate(#{translateX},0)")
                        .append('path')
                        .datum(data)
                        .attr('d', area)

                else
                # ...but when zoomed in, we show the waveform with a line
                    line = d3.svg.line()
                        .x(sampleX)
                        .y( (d) -> y(d) ) # TODO. just y
                        .interpolate('linear')

                    sel.append('g')
                        .attr('class','line')
                        .attr('transform',"translate(#{translateX},0)")
                        .append('path')
                        .datum(data)
                        .attr('d', line);
                


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


    # getter/setter for vertical zoom
    waveform.verticalZoom = (_verticalZoom) ->
        if not arguments.length then return verticalZoom;
        verticalZoom = _verticalZoom
        return waveform
    

    # inherit properties from the commonProperties
    return d3.rebind(waveform, commonProperties(), 'x', 'width', 'height', 'timeline')