var commonProperties = require('./commonProperties'),
    fx = require('./fx'),
    uid = require('./uid');


// component for drawing waveforms in an svg element
module.exports = function(){
    // var channel, 
    //     sampleRate, 
    var startOffset = 0, 
        timeline;

    // There are 3 slightly different ways of drawing the waveform, which depend
    // on the zoom level. These parameters are in units of 'samples per pixel'
    // and can be used to determine the switchover between drawing modes
    var DISPLAY_ABOVE_AND_BELOW_CUTOFF = 10;
    var DISPLAY_AS_LINE_CUTOFF = 1;

    var waveform = function(){

        var selection = this;

        function draw(_x){

            selection.each(function(d){
                
                var sel = d3.select(this);

                var x = _x || waveform.x(),
                    domain = x.domain(),
                    range = x.range(),
                    channel = d.channel,
                    sampleRate = d.buffer.sampleRate,
                    startOffset = d.startTime || 0;

                x = d3.scale.linear().range(range).domain([domain[0] - startOffset, domain[1] - startOffset])

                var width = waveform.width(),
                    height = waveform.height() || 128,
                    startTime = Math.max(x.domain()[0],0);

                // make a copy, so we can mess with the data without affecting the original
                var data = new Float32Array(channel),

                // trim the data according to the range of the x scale
                data = data.subarray(startTime * sampleRate, domain[1] * sampleRate);

                var samplesPerPixel = Math.max(~~((Math.abs(domain[1] - domain[0]) * sampleRate) / width), 1);

                data = fx.thinOut(data, samplesPerPixel, 
                                        samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF
                                        ? 'max'
                                        : 'first');

                var y = d3.scale.linear()
                    .range([height,0])
                    .domain([1,-1]);

                var translateX = 0;

                function sampleX(d, i){
                    return x(i*samplesPerPixel/sampleRate + startTime);
                }

                sel.text('');
                // when zoomed out, we do it with an area...
                if (samplesPerPixel > DISPLAY_AS_LINE_CUTOFF){
                    var area = d3.svg.area()
                        .x(sampleX)
                        .y0(samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF
                            ? function(d){return y(-d)}
                            : y(0)
                            )
                        .y1(y);

                    sel.append('g')
                        .attr('class','area')
                        .attr('transform','translate('+translateX+',0)')
                        .append('path')
                        .datum(data)
                        .attr('d', area);
                }else{
                // ...but when zoomed in, we show the waveform with a line
                    var line = d3.svg.line()
                        .x(sampleX)
                        .y(function(d){return y(-d)})
                        .interpolate('linear');

                    sel.append('g')
                        .attr('class','line')
                        .attr('transform','translate('+translateX+',0)')
                        .append('path')
                        .datum(data)
                        .attr('d', line);
                }
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
    waveform.timeline = function(_timeline){
        if (!arguments.length) return _timeline;
        timeline = _timeline;
        return waveform;
    }

    // inherit properties from the commonProperties
    return d3.rebind(waveform, commonProperties(), 'x', 'width', 'height');
}