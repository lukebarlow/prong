
var commonProperties = require('../commonProperties'),
    uid = require('../uid');

module.exports = function(){
    var key,
        colour,
        clickHandler = null;

    var note = function(){
        var selection = this;
        var startOffset = 0;

        function draw(_x){

            selection.each(function(d){

                var sel = d3.select(this);

                var x = _x || note.x(),
                    width = note.width(),
                    height = note.height() || 128,
                    domain = x.domain(),
                    range = x.range(),
                    startOffset = d.startTime || 0,
                    notes = sel.datum()[key] || [], // notes are time, pitch pairs
                    y = y || d3.scale.linear().range([height, 0]).domain([60, 90]);

                x = d3.scale.linear().range(range).domain([domain[0] - startOffset, domain[1] - startOffset])

                var startTime = Math.max(x.domain()[0],0);
                
                var visibleNotes = notes.filter(function(note){
                    return note[0] > startTime && note[0] < domain[1];
                })

                var noteHeight = 2 * Math.abs(y(0) - y(1))

                sel.selectAll('.note').remove()
                // now draw the new ones
                sel.selectAll('.note')
                    .data(visibleNotes)
                    .enter()
                    .append('rect')
                    .attr('class','note')
                    .style('fill',colour)
                    .attr('x', function(d){return x(d[0])})
                    .attr('width',10)
                    .attr('y', function(d){
                        return y(d[1]) - d[2]/10})
                    .attr('height', function(d){
                        return 10
                        //return d[2]/10
                    })
                    .style('cursor','pointer')
                    .on('click', function(d){
                        if (clickHandler) clickHandler(d[1])
                    })
            })
        }

        draw();

        var timeline = note.timeline();

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

    note.y = function(_y){
        if (!arguments.length) return y;
        y = _y;
        return note;
    }

    note.key = function(_key){
        if (!arguments.length) return key;
        key = _key;
        return note;
    }

    note.colour = function(_colour){
        if (!arguments.length) return colour;
        colour = _colour;
        return note;
    }

    note.clickHandler = function(_clickHandler){
        if (!arguments.length) return clickHandler;
        clickHandler = _clickHandler;
        return note;
    }


    // inherit properties from the commonProperties
    return d3.rebind(note, commonProperties(), 'x', 'width', 'height', 'timeline');
}