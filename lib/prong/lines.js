// this is the visual component which is used to draw the note onset lines
var commonProperties = require('./commonProperties'),
    uid = require('./uid');

module.exports = function(){
    var key,
        timeline,
        colour;

    var lines = function(){
        var selection = this;
        var startOffset = 0;

        function draw(_x){

            selection.each(function(d){

                var sel = d3.select(this);

                var x = _x || lines.x(),
                    width = lines.width(),
                    height = lines.height() || 128,
                    domain = x.domain(),
                    range = x.range(),
                    startOffset = d.startTime || 0;
                    times = sel.datum()[key] || [];

                x = d3.scale.linear().range(range).domain([domain[0] - startOffset, domain[1] - startOffset])

                var startTime = Math.max(x.domain()[0],0);
                
                var visibleTimes = times.filter(function(time){
                    return time > startTime && time < domain[1];
                })

                sel.selectAll('.onset').remove()
                // now draw the new ones
                sel.selectAll('.onset')
                    .data(visibleTimes)
                    .enter()
                    .append('rect')
                    .attr('class','onset')
                    .style('fill',colour)
                    .attr('x', function(d){
                        //return x(d + track.startTime);
                        return x(d)
                    })
                    .attr('width',1)
                    .attr('y', 0)
                    .attr('height', height)

            })

            
        }

        draw();

        if (timeline){
            // this timing logic tries to keep waveform redrawing as smooth
            // as possible. It times how long it takes to redraw the waveform
            // and makes sure not to redraw more frequently than that

            var lastTimeout = null,
                drawingTime = null,
                lastDrawingStart = null;

            function drawAndTime(){
                var start = new Date();
                draw();
                drawingTime = new Date() - start;
            }

            timeline.on('change.' + uid(), function(){
                if (lastTimeout) clearTimeout(lastTimeout);
                if (!lastDrawingStart || (new Date() - lastDrawingStart) > (drawingTime * 2)){
                    drawAndTime();
                }else{
                    lastTimeout = setTimeout(function(){
                        drawAndTime();
                        lastTimeout = null;
                    }, 50);  
                }    
            })
        }
    }

    // by setting the timeline property for a waveform, you bind the waveform
    // to that timeline so that it will listen to change events and redraw
    // itself whenever the timeline changes
    lines.timeline = function(_timeline){
        if (!arguments.length) return timeline;
        timeline = _timeline;
        return lines;
    }

    lines.key = function(_key){
        if (!arguments.length) return key;
        key = _key;
        return lines;
    }

    lines.colour = function(_colour){
        if (!arguments.length) return colour;
        colour = _colour;
        return lines;
    }

    // inherit properties from the commonProperties
    return d3.rebind(lines, commonProperties(), 'x', 'width', 'height');
}