var commonProperties = require('./commonProperties');

// a timeline is the axis which usually appears above a number of tracks
// in a sequence. It also manages dragging to zoom, like Logic and Cubase, and
// horizontal scrolling to move back and forth along the timeline
module.exports = function(){

    var dispatch = d3.dispatch('change'), // event dispatcher
        selection, // remembers the selection this component is bound to
        axis, // the underlying d3.svg.axis object
        secondsFormatter, // formtter
        scrollZone; // the selection on which this timeline will detect scroll events

    function setSecondsFormatter(){
        secondsFormatter = timeline.x().tickFormat(10);
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
    }

    function notBelowZero(domain){
        // domain cannot go below zero
        if (domain[0] < 0){
            domain[1] -= domain[0];
            domain[0] = 0;
        }
        return domain;
    }

    // handler for mousewheel events
    function mouseWheel(){
        if (!d3.event.wheelDeltaX) return;
        d3.event.preventDefault();
        if (scrollTimeoutId != null){
            window.clearTimeout(scrollTimeoutId)
        }

        var delta = d3.event.wheelDeltaX / 12;
        var x = timeline.x();
        var deltaTime = x.invert(0) - x.invert(delta);

        var before = x(0);
        var domain = x.domain();
        domain[0] += deltaTime;
        domain[1] += deltaTime;
        domain = notBelowZero(domain);
        x.domain(domain);

        var after = x(0);
        timeline.x(x).redraw();
        
        scrollTimeoutId = window.setTimeout(scrollFinished, 100);

        dispatch.change(x);
    }

    function timeline(_selection){
        selection = _selection;
        var x = timeline.x();
        setSecondsFormatter();
        var width = Math.abs(x.range()[1] - x.range()[0]);
        axis = d3.svg.axis()
                    .scale(x).tickSize(10, 5, 0)
                    .tickSubdivide(10)
                    .tickFormat(formatSeconds);
        
        
        var dragging = false;
        var downTime; // the mapped time which the drag starts on
        var downY; // the pixel y (relative to the timeline) which the drag starts on
        var lhs, rhs; // the amount of time to the left and right of the downTime when the drag starts

    
        function dragStart(pointerX, pointerY){
            var x = timeline.x()
            dragging = true;
            downY = pointerY;
            downTime = x.invert(pointerX);
            var downDomain = x.domain();
            lhs = downTime - downDomain[0];
            rhs = downDomain[1] - downTime;
        }

        function dragMove(){
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
            setSecondsFormatter();
            selection.call(axis.scale(x));
            dispatch.change(x);
        }

        function dragEnd(){
            dragging = false;
            d3.select(window)
                .on('mousemove.timeline', null)
                .on('mouseup.timeline', null);
            dispatch.change(x);
        }

        selection.attr('class','timeline')
            .attr('width',width)
            .attr('height',50)
            .call(axis);

        var axisOverlay = selection.append('rect')
            .attr('class','timelineOverlay')
            .attr('x',0)
            .attr('y', 0)
            .attr('width', width)
            .attr('height', 50)
            .attr('fill','transparent');

        axisOverlay.on('mousedown.timeline', function(d){
            var pointer = d3.mouse(selection.node());
            dragStart(pointer[0],pointer[1]);
            d3.select(window)
                .on('mousemove.timeline', dragMove)
                .on('mouseup.timeline', dragEnd);
        });
    }

    timeline.redraw = function(){
        var x = timeline.x();
        setSecondsFormatter();
        selection.call(axis.scale(x));
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
        scrollZone.on('mousewheel', mouseWheel)
        return timeline;
    }

    return d3.rebind(timeline, commonProperties(), 'x', 'width',' height');
}