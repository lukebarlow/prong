var commonProperties = require('../commonProperties'),
    fx = require('../analysis/fx'),
    uid = require('../uid');


// component for drawing waveforms in an svg element
module.exports = function(){
    // var channel, 
    //     sampleRate, 
    var startOffset = 0,
        verticalZoom = 1;

    // There are 3 slightly different ways of drawing the waveform, which depend
    // on the zoom level. These parameters are in units of 'samples per pixel'
    // and can be used to determine the switchover between drawing modes
    var DISPLAY_ABOVE_AND_BELOW_CUTOFF = 10,
        DISPLAY_AS_LINE_CUTOFF = 1,
        WIDE_ZOOM = 5000,
        MEDIUM_ZOOM = 1000;


    var waveform = function(){
        var selection = this;
        function draw(){

            selection.each(function(d){
                var sel = d3.select(this);
                d.startTime = d.startTime || 0;

                /* there are essentially two scales at play
                    1. clipScale - this maps the sequence timeline
                    to the clip timeline. It can also be used to determine which
                    time slices of the channel are actually visible. The domain
                    and range will be shrunk to fit what's actually visible

                    2. sequenceScale - this maps the time of the sequence to the
                    pixels on the screen - the normal x scale. The domain is
                    sequence time and the range is pixels on screen.

                    by combining the two, we can map clip time to pixels
                */

                var x = waveform.x(),
                    domain = x.domain(),
                    range = x.range(),
                    channel = d.channel,
                    sampleRate = d.buffer.sampleRate,
                    startOffset = (d.startTime || 0),
                    length;

                d.clipStart = d.clipStart || 0;
                d.clipEnd = d.clipEnd || (channel.length / sampleRate);

                var length = d.clipEnd - d.clipStart,
                    clipDomain = [d.clipStart, d.clipEnd],
                    clipRange = [d.startTime, d.startTime + length],
                    clipScale = d3.scale.linear().range(clipRange).domain(clipDomain),
                    clipStart = d.clipStart,
                    viewStart = clipStart + Math.max(domain[0] - d.startTime, 0),
                    viewEnd = d.clipEnd - Math.max(d.startTime + length - domain[1], 0);

                // clear any previous areas and lines
                sel.selectAll('.area').remove();
                sel.selectAll('.line').remove();

                // if the waveform is out of view, then nothing more to do
                if (viewStart > viewEnd) return;

                var width = waveform.width(),
                    height = waveform.height() || 128,
                    samplesPerPixel = Math.max(~~((Math.abs(domain[1] - domain[0]) * sampleRate) / width), 1);

                if (!('_cache' in d)){
                    d._cache = {}
                }

                var data;

                if (!(WIDE_ZOOM in d._cache)){
                    d._cache[WIDE_ZOOM] = fx.thinOut(channel, WIDE_ZOOM)
                }

                if (!(MEDIUM_ZOOM in d._cache)){
                    d._cache[MEDIUM_ZOOM] = fx.thinOut(channel, MEDIUM_ZOOM)
                }

                // we cache the thinned data at two levels, so zooming is
                // faster
                if (samplesPerPixel >= WIDE_ZOOM){
                    samplesPerPixel = WIDE_ZOOM;
                    data = d._cache[WIDE_ZOOM].slice(viewStart * sampleRate / WIDE_ZOOM,
                        viewEnd * sampleRate / WIDE_ZOOM);
                }else 
                if (samplesPerPixel >= MEDIUM_ZOOM){
                    samplesPerPixel = MEDIUM_ZOOM;
                    data = d._cache[MEDIUM_ZOOM].slice(viewStart * sampleRate / MEDIUM_ZOOM,
                        viewEnd * sampleRate / MEDIUM_ZOOM);
                }else{
                    data = channel.subarray(viewStart * sampleRate, viewEnd * sampleRate);
                    data = fx.thinOut(data, samplesPerPixel, 
                        samplesPerPixel > DISPLAY_ABOVE_AND_BELOW_CUTOFF
                        ? 'max' : 'first');
                }

                var y = d3.scale.linear()
                    .range([height,0])
                    .domain([1 / verticalZoom,-1 / verticalZoom]);

                var translateX = 0;

                function sampleX(d, i){
                    return x(clipScale(i*samplesPerPixel/sampleRate + viewStart));
                }

                // when zoomed out, we do it with an area...
                if (samplesPerPixel > DISPLAY_AS_LINE_CUTOFF){

                    canvas = sel.node()

                    context = canvas.getContext('2d');
                    context.clearRect( 0, 0, 800, 200);

                    context.beginPath();
                    // along the top forwards
                    data.forEach(function(d, i){
                      context.lineTo(sampleX(d, i), y(-d));
                    });

                    // then along the bottom going backwards
                    for (var i=data.length-1;i>=0;i--){
                        var d = data[i]
                        context.lineTo(sampleX(d,i), y(d));
                    }

                    context.closePath();
                    context.fillStyle = 'steelblue';
                    context.fill();

                }else{
                // ...but when zoomed in, we show the waveform with a line

                    console.log('line')
                    // var line = d3.svg.line()
                    //     .x(sampleX)
                    //     .y(function(d){return y(-d)})
                    //     .interpolate('linear');

                    // sel.append('g')
                    //     .attr('class','line')
                    //     .attr('transform','translate('+translateX+',0)')
                    //     .append('path')
                    //     .datum(data)
                    //     .attr('d', line);
                }
            })
        }

        draw();

        var timeline = waveform.timeline();

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

    // getter/setter for vertical zoom
    waveform.verticalZoom = function(_verticalZoom){
        if (!arguments.length) return verticalZoom;
        verticalZoom = _verticalZoom;
        return waveform;
    }

    // inherit properties from the commonProperties
    return d3.rebind(waveform, commonProperties(), 'x', 'width', 'height', 'timeline');
}