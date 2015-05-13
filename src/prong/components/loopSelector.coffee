d3 = require('../d3-prong-min')
commonProperties = require('../commonProperties')

module.exports = ->

    dispatch = d3.dispatch('change', 'changing')
    loopLeft = null
    loopRight = null
    dragBar = null
    dragStartBar = null
    dragEndBar = null
    disabled = false
    selection = null
    
    xPosition = (node) -> 
        loopSelector.timeline().x().invert(d3.mouse(node)[0])


    stopPropagation = ->
        if d3.event
            e = d3.event.sourceEvent or d3.event
            e.preventDefault() 
            e.stopPropagation()


    updateDragBar = ->
        if not dragBar then return

        x = loopSelector.timeline().x()
        [s, e] = x.range()
        start = Math.max(s, x(loopLeft))
        end = Math.min(e, x(loopRight))
        width = Math.max(end - start, 0)
        endsWidth = Math.max(1, Math.min(width / 4, 10))
        dragBar
            .attr('x', start)
            .attr('width', width)
            .classed('disabled', disabled)
        dragStartBar
            .attr('x', start)
            .attr('width', endsWidth)
        dragEndBar
            .attr('x', end - endsWidth)
            .attr('width', endsWidth)


    draw = (selection) ->
        dragBar = null
        dragStartBar = null
        dragEndBar = null
        x = loopSelector.timeline().x()
        width = x.range()[1] - x.range()[0]
        movedSinceMousedown = false

        selection.on 'dblclick', stopPropagation

        drawDragBar = ->
            dragBar = selection.append('rect')
                .attr('class','loop')
                .attr('y', -20)
                .attr('height', '20')
                .call(barDrag)

            dragStartBar = selection.append('rect')
                .attr('class','loopStart')
                .attr('y', -20)
                .attr('height', '20')
                .attr('width', 10)
                .call(barStartDrag)

            dragEndBar = selection.append('rect')
                .attr('class','loopEnd')
                .attr('y', -20)
                .attr('height', '20')
                .attr('width', 10)
                .call(barEndDrag)

            updateDragBar()

            dragBar
                .on('mousedown', mousedownHandler)
                .on('mouseup', mouseupHandler)

        mousedownHandler = ->
            movedSinceMousedown = false


        mouseupHandler = ->
            if not movedSinceMousedown
                disabled = not disabled
                dragBar.classed('disabled', disabled)
                dispatch.change(loopLeft, loopRight, disabled)

        dragstartTime = null

        dragstart = ->
            movedSinceMousedown = false
            #debugger
            stopPropagation()
            #loopLeft = loopRight = xPosition(this)
            dragstartTime = xPosition(this)
            if not dragBar then drawDragBar()
            

        dragmove = ->
            if not movedSinceMousedown
                movedSinceMousedown = true
                loopLeft = loopRight = dragstartTime

            if disabled
                disabled = false
                dragBar.classed('disabled', disabled)
            position = xPosition(this)
            loopRight = position
            updateDragBar()
            dispatch.changing(loopLeft, loopRight, disabled)
            
        dragend = ->
            dispatch.change(loopLeft, loopRight, disabled)

        drag = d3.behavior.drag()
            .on('dragstart', dragstart)
            .on('drag', dragmove)
            .on('dragend', dragend)

        dragDelta = -> x.invert(d3.event.dx) - x.invert(0)

        dragstartOnDragBar = ->
            if not disabled
                stopPropagation()

        dragendOnDragBar = ->
            stopPropagation()
            dispatch.change(loopLeft, loopRight, disabled)

        barDrag = d3.behavior.drag()
            .on('dragstart', dragstartOnDragBar)
            .on('dragend', dragendOnDragBar)
            .on 'drag', ->
                movedSinceMousedown = true
                stopPropagation()
                delta = dragDelta()
                loopLeft += delta
                loopRight += delta
                updateDragBar()
                dispatch.changing(loopLeft, loopRight, disabled)

        barEndDrag = d3.behavior.drag()
            .on('dragstart', dragstartOnDragBar)
            .on('dragend', dragendOnDragBar)
            .on 'drag', ->
                movedSinceMousedown = true
                stopPropagation()
                loopRight = Math.max(loopRight + dragDelta(), loopLeft)
                updateDragBar()
                dispatch.changing(loopLeft, loopRight, disabled)

        barStartDrag = d3.behavior.drag()
            .on('dragstart', dragstartOnDragBar)
            .on('dragend', dragendOnDragBar)
            .on 'drag', ->
                movedSinceMousedown = true
                stopPropagation()
                loopLeft = Math.min(loopLeft + dragDelta(), loopRight)
                updateDragBar()
                dispatch.changing(loopLeft, loopRight, disabled)

        selection.append('rect')
            .attr('class','loopSelector')
            .attr('x',0)
            .attr('y', -20)
            .attr('width', width)
            .attr('height', '20')

        loopSelector.timeline().on 'change', ->
            if dragBar
                updateDragBar()

        selection.call(drag)

        if loopLeft != null and loopRight != null
            drawDragBar()


    loopSelector = (_selection) ->
        selection = _selection
        draw(_selection)

    
    loopSelector.domain = (domain) ->
        if not arguments.length
            return [loopLeft, loopRight]
        [loopLeft, loopRight] = domain
        if selection and (not dragBar)
            draw(selection)
            dispatch.change(loopLeft, loopRight, disabled)
        updateDragBar()
        return loopSelector


    loopSelector.on = (type, listener) ->
        dispatch.on(type, listener)
        return loopSelector


    loopSelector.disabled = (_disabled) ->
        if not arguments.length then return disabled
        disabled = _disabled
        if dragBar
            dragBar.classed('disabled', disabled)
        return loopSelector


    loopSelector = d3.rebind(loopSelector, commonProperties(), 'timeline')