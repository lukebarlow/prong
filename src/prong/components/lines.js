// this is the visual component which is used to draw the note onset lines
var commonProperties = require('../commonProperties'),
    uid = require('../uid');

module.exports = function(){
    var key,
        colour,
        labels = false; // boolean, determines whether to show labels

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

                if (labels){
                    var yOffset = times.indexOf(visibleTimes[0]) % 3;
                    sel.selectAll('text').remove()
                    sel.selectAll('text')
                        .data(visibleTimes)
                        .enter()
                        .append('text')
                        .style('fill',colour)
                        .style('font-size','10pt')
                        .attr('x', function(d){
                            return x(d)+1
                        })
                        .attr('width',1)
                        .attr('y', function(d,i){return ((i+yOffset)%3) * 14 + 15})
                        .attr('height', height)
                        .text(function(d){return d3.round(d,2)})
                }
            })
        }

        draw();

        var timeline = lines.timeline();

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

    lines.key = function(_key){
        if (!arguments.length) return key;
        key = _key;
        return lines;
    }

    lines.labels = function(_labels){
        if (!arguments.length) return labels;
        labels = _labels;
        return lines;
    }

    lines.colour = function(_colour){
        if (!arguments.length) return colour;
        colour = _colour;
        return lines;
    }

    // inherit properties from the commonProperties
    return d3.rebind(lines, commonProperties(), 'x', 'width', 'height', 'timeline');
}