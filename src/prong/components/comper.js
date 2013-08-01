var commonProperties = require('../commonProperties'),
    uid = require('../uid'),
    history = require('../history/history'),
    encoder = require('../history/editEncoding');

module.exports = function(){

    var editList = [{'track' : 0, start : 0}],
        selection,
        dispatch = d3.dispatch('change'),
        historyId, // the query string parameter name this uses to track history
        historyTracker; // the prong.history object used to track history

    // calculates the regions inbetween the edits, return a list of
    // dictionaries, each with a start and end property
    function inbetweens(track, edits, x){
        var start = x.domain()[0],
            end = x.domain()[1];
        // if no comp regions on this track, then just return a single
        // 'inbetween' which spans the whole duration
        if (edits.length == 0){
            return [{'track':track, 'start':start, 'end':end}];  
        }
        var regions = [];
        // if first edit is not at the start, then we need a start region
        if (edits[0].start > start){
            regions.push({'track':track, 'start':start, 'end':edits[0].start});
        }
        // now the middle regions
        for (var i=0;i<edits.length-1;i++){
            var edit = edits[i];
            regions.push({'track':track, 'start':edits[i].end, 'end':edits[i+1].start});
        }
        // and finally the region on the end, if necessary
        if (edits[edits.length-1].end < end){
            regions.push({'track':track, 'start':edits[edits.length-1].end, 'end':end});
        }
        return regions;
    }



    // if element is in array and not the last element of that array, then this
    // function will return the following element in the array. Otherwise, it
    // will return null
    function nextInArray(array, element){
        var index = array.indexOf(element);
        if (index == -1) return null;
        if (index == array.length - 1) return null;
        return array[index+1];
    }

    function previousInArray(array, element){
        var index = array.indexOf(element)
        if (index == -1) return null;
        if (index == 0) return null;
        return array[index-1];
    }

    // returns the edit object which is active at the specified time
    function editAtTime(time){
        for (var i=0;i<editList.length;i++){
            var edit = editList[i];
            if (edit.start <= time && edit.end > time){
                return edit;
            }
        }
        return null;
    }

    function liveTrackAtTime(time){
        var edit = editAtTime(time);
        return edit ? edit.track : null;
    }

    function compStart(){
        // need to define what we're doing. We could be dragging one
        // of the resizers (on either end of a region), dragging a region
        // or swiping to create a new region
        var target = this,
            eventTarget = d3.select(d3.event.target),
            offset,
            edit = eventTarget.datum(),
            nextEdit = nextInArray(editList, edit),
            previousEdit = previousInArray(editList, edit);

        var mode = eventTarget.classed('start') ? 'start' :
                   eventTarget.classed('end') ? 'end' :
                   eventTarget.classed('comp') ? 'dragging' : 
                   eventTarget.classed('inbetween') ? 'swiping' : null;

        var resizing = (mode == 'start' || mode == 'end');

        var w = d3.select(window)
            .on('mousemove.comp', compMove)
            .on('mouseup.comp', compUp);

        var x = comper.x();
        var previousTime = x.invert(mouse()[0]);

        function mouse() {
            var touches = d3.event.changedTouches;
            return touches ? d3.touches(target, touches)[0] : d3.mouse(target);
        }

        function removeNextEdit(){
            editList.remove(nextEdit);
            nextEdit = nextInArray(editList, edit);
            if (nextEdit && (nextEdit.track == edit.track)){
                editList.remove(nextEdit);
            }
        }

        function removePreviousEdit(){
            editList.remove(previousEdit);
            previousEdit = previousInArray(editList, edit);
            // if the new 'previousEdit' is the same track as
            // the one we're editing, then we merge
            if (previousEdit && (previousEdit.track == edit.track)){
                editList.remove(edit);
            }
        }

        function compMove(){

            var time = x.invert(mouse()[0]);
            var moved = false;

            // cannot resize slices smaller than the lowerLimit
            var lowerLimit = x.invert(2) - x.invert(0);

            switch(mode){
                case 'start':
                    // detects moving the start of the region so that it
                    // wipes out the region before
                    if (time > edit.end - lowerLimit){
                        time = edit.end - lowerLimit;
                    }
                    time = Math.max(0, time)
                    if (previousEdit && (time <= previousEdit.start)){
                        removePreviousEdit();
                    }
                    edit.start = time;
                break;
                case 'end':
                    if (time < edit.start + lowerLimit){
                        time = edit.start + lowerLimit;
                    }
                    if (nextEdit){
                        if (time > nextEdit.end){
                            removeNextEdit();
                        }
                        if (nextEdit){
                            nextEdit.start = time;
                        }
                    }else{
                        edit.end = time;
                    }
                break;
                case 'dragging':
                    var diff = time - previousTime
                    // don't move if it's the first one
                    if (editList.indexOf(edit) != 0){
                        edit.start += diff;
                    }
                    
                    if (nextEdit){
                        nextEdit.start += diff;
                        if (nextEdit.start > nextEdit.end){
                            removeNextEdit();
                        }
                    }
                    if (previousEdit && (edit.start < previousEdit.start)){
                        removePreviousEdit();
                    }
                    previousTime = time;
                break;
                case 'swiping':
                    // the first mouse movement after mouse down in an inbetween
                    // region determines whether we swipe the beginning or end
                    // of the region

                    // don't start the swipe for tiny mouse movements
                    if (Math.abs(x(time) - x(previousTime)) < 4){
                        return
                    } 
                    mode = time > previousTime ? 'end' : 'start';
                    
                    var bittenEdit = editAtTime(time);
                    if (!bittenEdit) return;
                    var bittenTrack = bittenEdit.track;
                    if (mode == 'start'){
                        edit = {'track' : edit.track, 'start' : time};
                        editList.push(edit);
                        var endEdit = {'track' : bittenTrack, 'start' : previousTime};
                        if (bittenEdit.end) endEdit.end = bittenEdit.end;
                        editList.push(endEdit);
                    }else{
                        edit = {'track' : edit.track, 'start' : previousTime};
                        nextEdit = {'track' : bittenTrack, 'start' : time};
                        editList.push(edit);
                        editList.push(nextEdit);
                        if (bittenEdit.end) nextEdit.end = bittenEdit.end;
                    }


                    editList.sort(function(a,b){
                        return a.start - b.start;
                    })

                    previousEdit = previousInArray(editList, edit);
                break;
                case 'finished':
                    // do nothing
                break;
            }

            cleanup();
            draw();
        }

        function compUp(){
            w .on('mousemove.comp', null)
              .on('mouseup.comp', null);

            if (mode == 'swiping'){
                var trackClicked = edit.track;
                var editToMove = editAtTime(previousTime);
                editToMove.track = trackClicked;
                cleanup();
                draw();
            }

            dispatch.change();
            if (historyTracker){
                historyTracker.set(encoder.stringify(editList))
            }
        }
    }

    function cleanup(){
        selection.each(function(){
            var track = d3.select(this);
            track.selectAll('rect.comp').remove();
            track.selectAll('rect.start').remove();
            track.selectAll('rect.end').remove();
            track.selectAll('rect.inbetween').remove();
        });
    }

    function draw(){
        var x = comper.x(),
            domain = x.domain(),
            range = x.range(),
            end = domain[1];

        editList.forEach(function(d,i){
            d.end = i < (editList.length - 1) ? editList[i+1].start : d.end || end;
        })

        // this filter does a couple of things
        // 1. set the end time on each edit to be equivalent to start of next edit
        // 2. remove edits which are outside the current x scale
        var filteredEditList = editList.filter(function(d,i){
            return (d.end > domain[0] && d.start < domain[1]);
        });

        function start(d){
            return Math.max(x(d.start), range[0]);
        }

        function width(d){
            return Math.max(Math.min(x(d.end), range[1]) - start(d) - 1, 0);
        }

        selection.each(function(d,i){
            // get just the edits for this track
            var edits = filteredEditList.filter(function(d){return d.track == i});
            var track = d3.select(this);
            
            // listen for mousedown events on the whole track
            track.style("pointer-events", "all")
                .on("mousedown.comp", compStart)
                .on("touchstart.comp", compStart);

            track.selectAll('rect.comp')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x', start)
                .attr('width',width)
                .attr('y',0)
                .attr('height', 128)
                .attr('class','comp');

            track.selectAll('rect.inbetween')
                .data(inbetweens(i, edits, x))
                .enter()
                .append('rect')
                .attr('x', start)
                .attr('width', width)
                .attr('y',0)
                .attr('height', 128)
                .attr('class','inbetween');

            track.selectAll('rect.start')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x',function(d){return x(d.start) - 5})
                .attr('width', 10)
                .attr('y',0)
                .attr('height', 129)
                .attr('class', function(d){
                    var first = (editList.indexOf(d) == 0)
                    return 'resizer start ' + (first ? 'first' : '');
                });

            track.selectAll('rect.end')
                .data(edits)
                .enter()
                .append('rect')
                .attr('x',function(d){return x(d.end) - 5})
                .attr('width', 10)
                .attr('y',0)
                .attr('height', 129)
                .attr('class',function(d){
                    var last = editList.indexOf(d) == editList.length - 1;
                    return 'resizer end ' + (last ? 'last' : '');
                });
        })
    }

    var comper = function(_selection){
        selection = _selection;

        // if we have a historyId, then listen to changes to the url, and
        // set the editList from the current url
        if (historyId){
            historyTracker = history(historyId);
            historyTracker.on('change', function(value){
                editList = encoder.parse(value);
                comper.redraw();
            });
            editList = encoder.parse(historyTracker.get());
        }

        cleanup();
        draw();

        var timeline = comper.timeline();

        // if we have a timeline, then listen for changes on it
        if (timeline) timeline.on('change.' + uid(), function(x){
            comper.x(x).redraw();
        });

        
    }

    comper.liveTrackAtTime = liveTrackAtTime

    comper.editList = function(_editList){
        if (!arguments.length) return editList;
        editList = _editList;
        return comper;
    }

    comper.redraw = function(){
        cleanup();
        draw();
    }

    comper.history = function(_history){
        if (!arguments.length) return historyId;
        if (!_history){
            historyId = null;
        }else{
            if (_history == true){
                _history = 'comper-' + uid();
            }
            historyId = _history;
        }
        return comper;
    }

    /* for attaching event listeners */
    comper.on = function(type, listener){
        dispatch.on(type, listener)
    }

    return d3.rebind(comper, commonProperties(), 'x', 'timeline');
}