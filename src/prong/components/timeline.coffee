commonProperties = require('../commonProperties')
# d3 = require('d3')

#  a timeline is the axis which usually appears above a number of tracks
#  in a sequence. It also manages dragging to zoom, like Logic and Cubase, and
#  horizontal scrolling to move back and forth along the timeline
module.exports = ->

    dispatch = d3.dispatch('change','end','timeselect') #  event dispatcher
    selection = null #  remembers the selection this component is bound to
    axis = null #  the underlying d3.svg.axis object
    secondsFormatter = null #  formatter
    scrollZone = null #  the selection on which this timeline will detect scroll events
    zoomable = true


    setSecondsFormatter = ->
        ticks = numberOfTicks()
        secondsFormatter = timeline.x().tickFormat(ticks)
    

    formatSeconds = (seconds) ->
        if seconds >= 60
            minutes = Math.floor(seconds / 60)
            seconds = seconds % 60
            return minutes + ':' + ( if seconds < 10 then '0' else '') + secondsFormatter(seconds)
        else
            return secondsFormatter(seconds)
        

    scrollTimeoutId = null

    scrollFinished = ->
        scrollTimeoutId = null
        dispatch.end()
    

    notBelowZero = (domain) ->
        #  domain cannot go below zero
        if domain[0] < 0
            domain[1] -= domain[0]
            domain[0] = 0
        
        return domain
    

    numberOfTicks = ->
        x = timeline.x()
        width = Math.abs(x.range()[1] - x.range()[0])
        pixelsPerSecond = x(1) - x(0)
        divider = 50
        if x.domain()[0] > 60 then divider += 20
        if pixelsPerSecond > 120 then divider += 20
        ticks = Math.round(width / divider)
        axis.ticks(ticks)
        return ticks
    

    #  handler for mousewheel events
    mouseWheel = ->
        if (!d3.event.wheelDeltaX) then return

        if Math.abs(d3.event.wheelDeltaX) > Math.abs(d3.event.wheelDeltaY)
            d3.event.preventDefault()
            d3.event.stopPropagation()

        delta = d3.event.wheelDeltaX / 12
        x = timeline.x()

        #  if you hold alt key, then it zooms instead of scrolling
        if d3.event.altKey
            if (!zoomable) then return
            pointer = d3.mouse(selection.node())
            downTime = x.invert(pointer[0])
            downDomain = x.domain()
            lhs = downTime - downDomain[0]
            rhs = downDomain[1] - downTime
            zoomFactor = Math.pow(2, delta / 1200)
            newDomain = [downTime - (lhs / zoomFactor), downTime + (rhs / zoomFactor)]
            newDomain = notBelowZero(newDomain)
            timeline.domain(newDomain)
            return

        deltaTime = x.invert(0) - x.invert(delta)

        before = x(0)
        domain = x.domain()
        domain[0] += deltaTime
        domain[1] += deltaTime
        domain = notBelowZero(domain)
        x.domain(domain)

        after = x(0)
        timeline.x(x).redraw()
        
        if scrollTimeoutId != null
            window.clearTimeout(scrollTimeoutId)
        
        scrollTimeoutId = window.setTimeout(scrollFinished, 200)

        dispatch.change(x)


    updateMinorLines = (x) ->
        #  minor lines disapped in d3 version 3, so have to be done explicitly
        ticks = numberOfTicks()
        minorLines = selection.selectAll('line.minor').data(x.ticks(ticks * 5), (d) -> d)
        minorLines.attr('x1', x).attr('x2', x)
        minorLines.enter()
            .append('line')
            .attr('class', 'minor')
            .attr('y1', 0)
            .attr('y2', 5)
            .attr('x1', x)
            .attr('x2', x)
        minorLines.exit().remove()
    

    timeline = (_selection) ->
        selection = _selection
        x = timeline.x()
        width = Math.abs(x.range()[1] - x.range()[0])
        axis = d3.svg.axis()
            .scale(x)
            .tickSize(10, 5, 0)
            # .tickSubdivide(10)
            .ticks(width > 50 ? 10 : 2)
            .tickFormat(formatSeconds)
        setSecondsFormatter()
        
        dragging = false
        movedSinceDragStart = false
        downTime = null #  the mapped time which the drag starts on
        downY = null #  the pixel y (relative to the timeline) which the drag starts on
        lhs = null
        rhs = null # the amount of time to the left and right of the downTime when the drag starts

    
        dragStart = (pointerX, pointerY) ->
            d3.event.preventDefault()
            d3.event.stopPropagation()
            x = timeline.x()
            dragging = true
            movedSinceDragStart = false
            downY = pointerY
            downTime = x.invert(pointerX)
            downDomain = x.domain()
            lhs = downTime - downDomain[0]
            rhs = downDomain[1] - downTime
            dispatch.timeselect(downTime)
            if not zoomable then return
            prong._dragging = true


        dragMove = ->
            if not zoomable then return
            d3.event.preventDefault()
            d3.event.stopPropagation()
            pointer = d3.mouse(selection.node())
            pointerX = pointer[0]
            pointerY = pointer[1]
            if isNaN(downY) or not dragging
                return
            
            diff = pointerY - downY
            #  dragging down (positive diff) zooms in, centering on the point
            #  where you first clicked
            zoomFactor = Math.pow(2, diff/100)
            newDomain = [downTime - (lhs / zoomFactor), downTime + (rhs / zoomFactor)]
            newDomain = notBelowZero(newDomain)
            x = timeline.x().domain(newDomain)
            timeline.x(x)
            movedSinceDragStart = true
            setSecondsFormatter()
            selection.call(axis.scale(x))
            updateMinorLines(x)
            dispatch.change(x)
            prong._dragging = true

        
        dragEnd = ->
            dragging = false
            d3.select(window)
                .on('mousemove.timeline', null)
                .on('mouseup.timeline', null)
                
            if movedSinceDragStart
                # dispatch.change(x)
                dispatch.end(x)
            
            prong._dragging = false
        

        selection
            .attr('width',width)
            .call(axis)
        updateMinorLines(x)

        axisOverlay = selection.append('rect')
            .attr('class','timelineOverlay')
            .attr('x',0)
            .attr('y', 0)
            .attr('width', width)
            .attr('height', '100%')
            .attr('fill','transparent')

        axisOverlay.on 'mousedown.timeline', (d) ->
            pointer = d3.mouse(selection.node())
            dragStart(pointer[0],pointer[1])
            d3.select(window)
                .on('mousemove.timeline', dragMove)
                .on('mouseup.timeline', dragEnd)
            d3.event.preventDefault()


    timeline.fireChange = ->
        dispatch.change()
        timeline.redraw()
    

    timeline.redraw = ->
        x = timeline.x()
        setSecondsFormatter()
        selection.call(axis.scale(x))
        updateMinorLines(x)
        selection.select('.timelineOverlay')
            .attr('width', Math.abs(x.range()[1] - x.range()[0]))

        return timeline
    

    # for attaching event listeners
    timeline.on = (type, listener) ->
        dispatch.on(type, listener)
        return timeline


    timeline.scrollZone = (selection) ->
        if not arguments.length then return scrollZone
        scrollZone = selection
        if scrollZone
            scrollZone.on('mousewheel', mouseWheel)
            scrollZone.on 'DOMMouseScroll', ->
                if d3.event.axis == d3.event.HORIZONTAL_AXIS
                    d3.event.wheelDeltaX = d3.event.detail * -120
                    d3.event.wheelDeltaY = 0
                else
                    d3.event.wheelDeltaX = 0
                    d3.event.wheelDeltaY = d3.event.detail * -120
                mouseWheel()

        return timeline
    

    timeline.zoomable = (_zoomable) ->
        if not arguments.length then return zoomable
        zoomable = _zoomable
        return timeline
    

    timeline.domain = (domain) ->
        if not arguments.length then return timeline.x().domain()
        timeline.x().domain(domain)
        timeline.redraw()
        dispatch.change(timeline.x())
    

    timeline.rangeAndDomain = (range, domain) ->
        timeline.x().range(range).domain(domain)
        timeline.redraw()
        dispatch.change(timeline.x())
        return timeline


    return d3.rebind(timeline, commonProperties(), 'x', 'width',' height','sequence')
