commonProperties = require('../commonProperties')
d3 = require('d3-prong')
LoopSelector = require('./loopSelector')
History = require('../history/history')
prong = require('../')

#  a timeline is the axis which usually appears above a number of tracks
#  in a sequence. It also manages dragging to zoom, like Logic and Cubase, and
#  horizontal scrolling to move back and forth along the timeline
module.exports = ->

    dispatch = d3.dispatch('change', 'end', 'timeselect', 'loopChange', 
        'loopChanging') #  event dispatcher
    selection = null #  remembers the selection this component is bound to
    axis = null #  the underlying d3.svg.axis object
    secondsFormatter = null #  formatter
    scrollZone = null #  the selection on which this timeline will detect scroll events
    zoomable = true
    scrollable = true
    canSelectLoop = false
    loopSelector = null
    history = null
    loopDomain = [null, null] # only used to store loop domain before the loop
        # selector is created
    loopDisabled = false


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
            if not zoomable then return
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

        if not scrollable then return

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

    round = (d) ->
        return d3.round(d, 6)

    historyCodec = {

        stringify: ->
            domain = timeline.x().domain().map(round)
            loopDomain = timeline.loop().map(round)
            loopDisabled = timeline.loopDisabled()
            return "#{domain};#{loopDomain};#{if loopDisabled then 1 else 0}"

        parse: (s) ->
            if not s then return [null, null]
            [domain, loopDomain, loopDisabled] = s.split(';')
            domain = domain.split(',').map(parseFloat)
            loopDomain = loopDomain.split(',').map(parseFloat)
            loopDisabled = loopDisabled == '1'
            return [domain, loopDomain, loopDisabled]
    }


    createHistory = ->
        #debugger
        if not(historyKey = timeline.historyKey()) then return
        history = History(historyKey, historyCodec)

        update = (domain, loopDomain, loopDisabled) ->
            if domain then timeline.domain(domain)
            if loopDomain then timeline.loop(loopDomain)
            timeline.loopDisabled(loopDisabled)

        [domain, loopDomain, loopDisabled] = history.get()
        update(domain, loopDomain, loopDisabled)

        history.on 'change', ([domain, loopDomain, loopDisabled]) ->
            update(domain, loopDomain, loopDisabled)
            [start, end] = loopDomain or [null, null]
            dispatch.loopChange(start, end, loopDisabled)

    
    timeline = (_selection) ->
        selection = _selection
        x = timeline.x()
        width = Math.abs(x.range()[1] - x.range()[0])
        axis = d3.svg.axis()
            .scale(x)
            .tickSize(10, 5, 0)
            .ticks(width > 50 ? 10 : 2)
            .tickFormat(formatSeconds)
        setSecondsFormatter()
        
        dragging = false
        movedSinceDragStart = false
        downTime = null #  the mapped time which the drag starts on
        downY = null #  the pixel y (relative to the timeline) which the drag starts on
        lhs = null
        rhs = null # the amount of time to the left and right of the downTime when the drag starts
        lastPointerX = null

        createHistory()

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
            if not d3.event.altKey
                dispatch.timeselect(downTime)
            if not zoomable then return
            prong._dragging = true
            lastPointerX = pointerX

        dragMove = ->
            if not zoomable then return
            d3.event.preventDefault()
            d3.event.stopPropagation()
            pointer = d3.mouse(selection.node())
            pointerX = pointer[0]
            pointerY = pointer[1]
            if isNaN(downY) or not dragging
                return

            x = timeline.x()
            # dragging sideways moves the whole wave left and right
            deltaX = pointerX - lastPointerX
            lastPointerX = pointerX
            downTime += x.invert(pointerX) - x.invert(pointerX + deltaX)
            #  dragging down (positive diff) zooms in, centering on the point
            #  where you first clicked
            diff = pointerY - downY
            zoomFactor = Math.pow(2, diff/100)
            newDomain = [downTime - (lhs / zoomFactor), downTime + (rhs / zoomFactor)]
            x.domain(notBelowZero(newDomain))
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
                dispatch.end(x)
                if history then history.set()
            
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
            #.attr('height', '100%')
            .attr('fill','transparent')

        if canSelectLoop
            loopSelector = LoopSelector()
                .timeline(timeline)
                .domain(timeline.loop())
                .disabled(timeline.loopDisabled())
                .on 'changing', (start, end, disabled) ->
                    dispatch.loopChanging(start, end, disabled)
                .on 'change', (start, end, disabled) ->
                    dispatch.loopChange(start, end, disabled)
                    if history then history.set()

            loopOverlay = selection.append('g')
                .call(loopSelector)

        mousedownHandler = (d) ->
            pointer = d3.mouse(selection.node())
            dragStart(pointer[0],pointer[1])
            d3.select(window)
                .on('mousemove.timeline', dragMove)
                .on('mouseup.timeline', dragEnd)
            d3.event.preventDefault()

        axisOverlay.on 'mousedown.timeline', mousedownHandler
        if scrollZone
            scrollZone.on 'mousedown.timeline', mousedownHandler


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


    timeline.scrollable = (_scrollable) ->
        if not arguments.length then return scrollable
        scrollable = _scrollable
        return timeline


    timeline.canSelectLoop = (_canSelectLoop) ->
        if not arguments.length then return canSelectLoop
        canSelectLoop = _canSelectLoop
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


    timeline.loop = (domain) ->
        if not arguments.length
            if loopSelector
                return loopSelector.domain()
            else
                return loopDomain or [null, null]
        if loopSelector
            loopSelector.domain(domain)
        else
            loopDomain = domain
        return timeline


    timeline.loopDisabled = (_disabled) ->
        if not arguments.length
            if loopSelector
                return loopSelector.disabled()
            else
                return loopDisabled
        if loopSelector
            loopSelector.disabled(_disabled)
        else
            loopDisabled = _disabled
        return timeline


    return d3.rebind(timeline, commonProperties(), 'x', 'width',' height',
            'sequence', 'historyKey')
