var commonProperties = require('../commonProperties');
//d3 = require('d3')

// a timeline is the axis which usually appears above a number of tracks
// in a sequence. It also manages dragging to zoom, like Logic and Cubase, and
// horizontal scrolling to move back and forth along the timeline
module.exports = function(){

    var dispatch = d3.dispatch('change','end','timeselect'), // event dispatcher
        selection, // remembers the selection this component is bound to
        axis, // the underlying d3.svg.axis object
        secondsFormatter, // formatter
        scrollZone, // the selection on which this timeline will detect scroll events
        zoomable = true;

    function setSecondsFormatter(){
        ticks = numberOfTicks();
        secondsFormatter = timeline.x().tickFormat(ticks);
    }

    function formatSeconds(seconds){
        if (seconds >= 60){
            var minutes = Math.floor(seconds / 60);
            var seconds = seconds % 60;
            return minutes + ':' + (seconds < 10 ? '0' : '') + secondsFormatter(seconds);
        }else{
            return secondsFormatter(seconds);
        }
    }

    var scrollTimeoutId = null;

    function scrollFinished(){
        scrollTimeoutId = null;
        dispatch.end();
    }

    function notBelowZero(domain){
        // domain cannot go below zero
        if (domain[0] < 0){
            domain[1] -= domain[0];
            domain[0] = 0;
        }
        return domain;
    }

    function numberOfTicks(){
        var x = timeline.x();
        var width = Math.abs(x.range()[1] - x.range()[0]);
        var pixelsPerSecond = x(1) - x(0);
        var divider = 50;
        if (x.domain()[0] > 60) divider += 20
        if (pixelsPerSecond > 120) divider += 20
        ticks = Math.round(width / divider);
        axis.ticks(ticks);
        return ticks;
    }

    // handler for mousewheel events
    function mouseWheel(){
        if (!d3.event.wheelDeltaX) return;

        if (Math.abs(d3.event.wheelDeltaX) > Math.abs(d3.event.wheelDeltaY)){
            d3.event.preventDefault();
            d3.event.stopPropagation();
        }

        var delta = d3.event.wheelDeltaX / 12;
        var x = timeline.x();

        // if you hold alt key, then it zooms instead of scrolling
        if (d3.event.altKey){
            if (!zoomable) return
            var pointer = d3.mouse(selection.node());
            var downTime = x.invert(pointer[0]);
            var downDomain = x.domain();
            lhs = downTime - downDomain[0];
            rhs = downDomain[1] - downTime;
            var zoomFactor = Math.pow(2, delta / 1200);
            var newDomain = [downTime - (lhs / zoomFactor), downTime + (rhs / zoomFactor)];
            newDomain = notBelowZero(newDomain);
            timeline.domain(newDomain);
            return
        }

    
        var deltaTime = x.invert(0) - x.invert(delta);

        var before = x(0);
        var domain = x.domain();
        domain[0] += deltaTime;
        domain[1] += deltaTime;
        domain = notBelowZero(domain);
        x.domain(domain);

        var after = x(0);
        timeline.x(x).redraw();
        
        if (scrollTimeoutId != null){
            window.clearTimeout(scrollTimeoutId)
        }
        scrollTimeoutId = window.setTimeout(scrollFinished, 200);

        dispatch.change(x);
    }

    function updateMinorLines(x){
        // minor lines disapped in d3 version 3, so have to be done explicitly
        ticks = numberOfTicks()
        var minorLines = selection.selectAll('line.minor')
                .data(x.ticks(ticks * 5), function(d) { return d; })
            minorLines.attr('x1', x).attr('x2', x);
            minorLines.enter()
                .append('line')
                .attr('class', 'minor')
                .attr('y1', 0)
                .attr('y2', 5)
                .attr('x1', x)
                .attr('x2', x);
            minorLines.exit().remove()
    }

    function timeline(_selection){
        selection = _selection;
        var x = timeline.x();
        var width = Math.abs(x.range()[1] - x.range()[0]);
        axis = d3.svg.axis()
            .scale(x)
            .tickSize(10, 5, 0)
            //.tickSubdivide(10)
            .ticks(width > 50 ? 10 : 2)
            .tickFormat(formatSeconds);
        setSecondsFormatter();
        
        var dragging = false,
            movedSinceDragStart = false,
            downTime, // the mapped time which the drag starts on
            downY, // the pixel y (relative to the timeline) which the drag starts on
            lhs, rhs; // the amount of time to the left and right of the downTime when the drag starts

    
        function dragStart(pointerX, pointerY){
            d3.event.preventDefault();
            d3.event.stopPropagation();
            var x = timeline.x()
            dragging = true;
            movedSinceDragStart = false;
            downY = pointerY;
            downTime = x.invert(pointerX);
            var downDomain = x.domain();
            lhs = downTime - downDomain[0];
            rhs = downDomain[1] - downTime;
            dispatch.timeselect(downTime);
            if (!zoomable) return;
            prong._dragging = true;
        }


        function dragMove(){
            if (!zoomable) return;
            d3.event.preventDefault();
            d3.event.stopPropagation();
            var pointer = d3.mouse(selection.node());
            var pointerX = pointer[0];
            var pointerY = pointer[1];
            if (isNaN(downY) || !dragging){
                return
            }
            var diff = pointerY - downY;
            // dragging down (positive diff) zooms in, centering on the point
            // where you first clicked
            var zoomFactor = Math.pow(2, diff/100);
            newDomain = [downTime - (lhs / zoomFactor), downTime + (rhs / zoomFactor)];
            newDomain = notBelowZero(newDomain);
            var x = timeline.x().domain(newDomain);
            timeline.x(x);
            movedSinceDragStart = true;
            setSecondsFormatter();
            selection.call(axis.scale(x));
            updateMinorLines(x);
            dispatch.change(x);
            prong._dragging = true;
        }

        
        function dragEnd(){
            dragging = false;
            d3.select(window)
                .on('mousemove.timeline', null)
                .on('mouseup.timeline', null);
                
            if (movedSinceDragStart){
                //dispatch.change(x);
                dispatch.end(x);
            }
            prong._dragging = false;
        }

        selection
            .attr('width',width)
            .call(axis);
        updateMinorLines(x);

        var axisOverlay = selection.append('rect')
            .attr('class','timelineOverlay')
            .attr('x',0)
            .attr('y', 0)
            .attr('width', width)
            .attr('height', '100%')
            .attr('fill','transparent');

        axisOverlay.on('mousedown.timeline', function(d){
            var pointer = d3.mouse(selection.node());
            dragStart(pointer[0],pointer[1]);
            d3.select(window)
                .on('mousemove.timeline', dragMove)
                .on('mouseup.timeline', dragEnd);
            d3.event.preventDefault();
        });
    }

    timeline.fireChange = function(){
        dispatch.change();
        timeline.redraw();
    }

    timeline.redraw = function(){
        var x = timeline.x();
        setSecondsFormatter();
        selection.call(axis.scale(x));
        updateMinorLines(x);
        selection.select('.timelineOverlay')
            .attr('width', Math.abs(x.range()[1] - x.range()[0]))

        return timeline;
    }

    /* for attaching event listeners */
    timeline.on = function(type, listener){
        dispatch.on(type, listener);
        return timeline;
    }

    timeline.scrollZone = function(selection){
        if (!arguments.length) return scrollZone;
        scrollZone = selection;
        if (scrollZone){
            scrollZone.on('mousewheel', mouseWheel)
        }
        return timeline;
    }

    timeline.zoomable = function(_zoomable){
        if (!arguments.length) return zoomable
        zoomable = _zoomable
        return timeline;
    }

    timeline.domain = function(domain){
        if (!arguments.length) return timeline.x().domain()
        timeline.x().domain(domain)
        timeline.redraw();
        dispatch.change(timeline.x());
    }

    timeline.rangeAndDomain = function(range, domain){
        timeline.x().range(range).domain(domain);
        timeline.redraw();
        dispatch.change(timeline.x());
        return timeline;
    }




    return d3.rebind(timeline, commonProperties(), 'x', 'width',' height','sequence');
}