var commonProperties = require('../commonProperties'),
    fx = require('../analysis/fx'),
    uid = require('../uid');

// a contour is very similar to a waveform, but usually at a much lower sample
// rate. i.e. it is a component for drawing a regularly spaced time series
// of values
module.exports = function(){ 
    var startOffset = 0,
        sampleRate;

    var contour = function(){

        var selection = this;

        function draw(){

            selection.each(function(d){
                
                var sel = d3.select(this);

                var x = contour.x(),
                    domain = x.domain(),
                    range = x.range(),
                    startOffset = d.startTime || 0;

                x = d3.scale.linear().range(range).domain([domain[0] - startOffset, domain[1] - startOffset])

                var width = contour.width(),
                    height = contour.height() || 128,
                    startTime = Math.max(x.domain()[0],0);

                var data = d,

                // trim the data according to the range of the x scale
                data = data.slice(startTime * sampleRate, domain[1] * sampleRate);

                var y = d3.scale.linear()
                    .range([height, 0])
                    .domain([0,1]);

                var translateX = 0;

                function sampleX(d, i){
                    return x(i/sampleRate + startTime);
                }

                sel.text('');
      
                var line = d3.svg.line()
                    .x(sampleX)
                    .y(y)
                    .interpolate('linear');

                sel.append('g')
                    .attr('class','line')
                    .attr('transform','translate('+translateX+',0)')
                    .append('path')
                    .datum(data)
                    .attr('d', line);
            })
        }

        draw();

        var timeline = contour.timeline();

        if (timeline){
            // this timing logic tries to keep contour redrawing as smooth
            // as possible. It times how long it takes to redraw the contour
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

    contour.sampleRate = function(_sampleRate){
        if (!arguments.length) return sampleRate;
        sampleRate = _sampleRate;
        return contour;
    }

    // inherit properties from the commonProperties
    return d3.rebind(contour, commonProperties(), 'x', 'width', 'height', 'timeline');
}