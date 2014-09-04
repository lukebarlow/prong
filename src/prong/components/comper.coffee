commonProperties = require('../commonProperties')
uid = require('../uid')
history = require('../history/history')
encoder = require('../history/editEncoding')

module.exports = ->

    editList = [{'track' : 0, start : 0}]
    selection = null
    dispatch = d3.dispatch('change')
    historyId = null # the query string parameter name this uses to track history
    historyTracker = null # the prong.history object used to track history

    # calculates the regions inbetween the edits, return a list of
    # dictionaries, each with a start and end property
    inbetweens = (track, edits, x) ->
        start = x.domain()[0]
        end = x.domain()[1]
        # if no comp regions on this track, then just return a single
        # 'inbetween' which spans the whole duration
        if edits.length == 0
            return [{'track':track, 'start':start, 'end':end}]
        
        regions = []
        # if first edit is not at the start, then we need a start region
        if edits[0].start > start
            regions.push({'track':track, 'start':start, 'end':edits[0].start})
        
        # now the middle regions
        for i in [0...edits.length-1]
            edit = edits[i]
            regions.push({'track':track, 'start':edits[i].end, 'end':edits[i+1].start})
        
        # and finally the region on the end, if necessary
        if edits[edits.length-1].end < end
            regions.push({'track':track, 'start':edits[edits.length-1].end, 'end':end})
        
        return regions


    # if element is in array and not the last element of that array, then this
    # function will return the following element in the array. Otherwise, it
    # will return null
    nextInArray = (array, element) ->
        index = array.indexOf(element)
        if (index == -1) then return null
        if (index == array.length - 1) then return null
        return array[index+1]


    previousInArray = (array, element) ->
        index = array.indexOf(element)
        if (index == -1) then return null
        if (index == 0) then return null
        return array[index-1]


    # returns the edit object which is active at the specified time
    editAtTime = (time) ->
        for i in [0...editList.length]
            edit = editList[i]
            if edit.start <= time && edit.end > time
                return edit
        return null


    liveTrackAtTime = (time) ->
        edit = editAtTime(time)
        return if edit then edit.track else null
    

    compStart = ->
        # need to define what we're doing. We could be dragging one
        # of the resizers (on either end of a region), dragging a region
        # or swiping to create a new region
        target = this
        eventTarget = d3.select(d3.event.target)
        offset = null
        edit = eventTarget.datum()
        nextEdit = nextInArray(editList, edit)
        previousEdit = previousInArray(editList, edit)

        mode = switch
            when eventTarget.classed('start') then 'start'
            when eventTarget.classed('end') then 'end'
            when eventTarget.classed('comp') then 'dragging'
            when eventTarget.classed('inbetween') then 'swiping'
            else null

        resizing = (mode == 'start' or mode == 'end')

        


        mouse = ->
            touches = d3.event.changedTouches
            return if touches then d3.touches(target, touches)[0] else d3.mouse(target)

        x = comper.x()
        previousTime = x.invert(mouse()[0])


        removeNextEdit = ->
            editList.remove(nextEdit)
            nextEdit = nextInArray(editList, edit)
            if nextEdit and (nextEdit.track == edit.track)
                editList.remove(nextEdit)

        removePreviousEdit = ->
            editList.remove(previousEdit)
            previousEdit = previousInArray(editList, edit)
            # if the new 'previousEdit' is the same track as
            # the one we're editing, then we merge
            if (previousEdit and (previousEdit.track == edit.track))
                editList.remove(edit)


        compMove = ->

            time = x.invert(mouse()[0])
            moved = false

            # cannot resize slices smaller than the lowerLimit
            lowerLimit = x.invert(2) - x.invert(0)

            switch mode
                when 'start'
                    # detects moving the start of the region so that it
                    # wipes out the region before
                    if time > edit.end - lowerLimit
                        time = edit.end - lowerLimit
                    
                    time = Math.max(0, time)
                    if previousEdit and (time <= previousEdit.start)
                        removePreviousEdit()
                    
                    edit.start = time

                when 'end'
                    if time < edit.start + lowerLimit
                        time = edit.start + lowerLimit
                    
                    if nextEdit
                        if (time > nextEdit.end)
                            removeNextEdit()
                        
                        if (nextEdit)
                            nextEdit.start = time
                    else
                        edit.end = time

                when 'dragging'
                    diff = time - previousTime
                    # don't move if it's the first one
                    if editList.indexOf(edit) != 0
                        edit.start += diff
                    
                    
                    if nextEdit
                        nextEdit.start += diff
                        if nextEdit.start > nextEdit.end
                            removeNextEdit()
                        
                    
                    if previousEdit and (edit.start < previousEdit.start)
                        removePreviousEdit()
                    
                    previousTime = time

                when 'swiping'
                    # the first mouse movement after mouse down in an inbetween
                    # region determines whether we swipe the beginning or end
                    # of the region

                    # don't start the swipe for tiny mouse movements
                    if Math.abs(x(time) - x(previousTime)) < 4
                        return
                    
                    mode = if time > previousTime then 'end' else 'start'
                    
                    bittenEdit = editAtTime(time)
                    if not bittenEdit then return
                    bittenTrack = bittenEdit.track
                    if mode == 'start'
                        edit = {'track' : edit.track, 'start' : time}
                        editList.push(edit)
                        endEdit = {'track' : bittenTrack, 'start' : previousTime}
                        if (bittenEdit.end) then endEdit.end = bittenEdit.end
                        editList.push(endEdit)
                    else
                        edit = {'track' : edit.track, 'start' : previousTime}
                        nextEdit = {'track' : bittenTrack, 'start' : time}
                        editList.push(edit)
                        editList.push(nextEdit)
                        if (bittenEdit.end) then nextEdit.end = bittenEdit.end
                    

                    editList.sort( (a,b) -> a.start - b.start )
        
                    previousEdit = previousInArray(editList, edit)

                # when 'finished'
                #     # do nothing
   

            cleanup()
            draw()
        

        compUp = ->
            w.on('mousemove.comp', null)
              .on('mouseup.comp', null)

            if mode == 'swiping'
                trackClicked = edit.track
                editToMove = editAtTime(previousTime)
                editToMove.track = trackClicked
                cleanup()
                draw()

            dispatch.change()
            if (historyTracker)
                historyTracker.set(encoder.stringify(editList), 'change edit')

        w = d3.select(window)
            .on('mousemove.comp', compMove)
            .on('mouseup.comp', compUp)


    cleanup = ->
        selection.each ->
            track = d3.select(this)
            track.selectAll('rect.comp').remove()
            track.selectAll('rect.start').remove()
            track.selectAll('rect.end').remove()
            track.selectAll('rect.inbetween').remove()

    draw = ->
        x = comper.x()
        domain = x.domain()
        range = x.range()
        end = domain[1]

        editList.forEach (d,i) ->
            d.end = if i < (editList.length - 1) then editList[i+1].start else d.end or end

        # this filter does a couple of things
        # 1. set the end time on each edit to be equivalent to start of next edit
        # 2. remove edits which are outside the current x scale
        filteredEditList = editList.filter (d,i) ->
            d.end > domain[0] and d.start < domain[1]


        start = (d) ->
            return Math.max(x(d.start), range[0])
        

        width = (d) ->
            return Math.max(Math.min(x(d.end), range[1]) - start(d) - 1, 0)


        selection.each (d,i) ->
            # get just the edits for this track
            edits = filteredEditList.filter( (d) -> d.track == i )
            track = d3.select(this)
            
            # listen for mousedown events on the whole track
            track.style("pointer-events", "all")
                .on("mousedown.comp", compStart)
                .on("touchstart.comp", compStart)

            track.selectAll('rect.comp')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x', start)
                .attr('width',width)
                .attr('y',0)
                .attr('height', 128)
                .attr('class','comp')

            track.selectAll('rect.inbetween')
                .data(inbetweens(i, edits, x))
                .enter()
                .append('rect')
                .attr('x', start)
                .attr('width', width)
                .attr('y',0)
                .attr('height', 128)
                .attr('class','inbetween')

            track.selectAll('rect.start')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x', (d) -> x(d.start) - 5)
                .attr('width', 10)
                .attr('y',0)
                .attr('height', 129)
                .attr 'class', (d) ->
                    first = (editList.indexOf(d) == 0)
                    return 'resizer start ' + (if first then 'first' else '')

            track.selectAll('rect.end')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x', (d) -> x(d.end) - 5)
                .attr('width', 10)
                .attr('y',0)
                .attr('height', 129)
                .attr 'class', (d) ->
                    last = editList.indexOf(d) == editList.length - 1
                    return 'resizer end ' + (if last then 'last' else '')
                


    comper = (_selection) ->
        selection = _selection

        # if we have a historyId, then listen to changes to the url, and
        # set the editList from the current url
        if historyId
            historyTracker = history(historyId)
            historyTracker.on 'change', (value) ->
                editList = encoder.parse(value)
                comper.redraw()
            editList = encoder.parse(historyTracker.get())
        
        cleanup()
        draw()

        timeline = comper.timeline()

        # if we have a timeline, then listen for changes on it
        if (timeline) then timeline.on 'change.' + uid(), (x) ->
            comper.x(x).redraw()


    comper.liveTrackAtTime = liveTrackAtTime

    comper.editList = (_editList) ->
        if not arguments.length then return editList
        editList = _editList
        return comper
    

    comper.redraw = ->
        cleanup()
        draw()
    

    comper.history = (_history) ->
        if not arguments.length then return historyId
        if not _history
            historyId = null
        else
            if _history == true
                _history = 'comper-' + uid()
            historyId = _history;
        return comper


    # for attaching event listeners
    comper.on = (type, listener) ->
        dispatch.on(type, listener)


    return d3.rebind(comper, commonProperties(), 'x', 'timeline')
