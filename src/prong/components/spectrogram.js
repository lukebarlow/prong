var commonProperties = require('../commonProperties'),
    FFT = require('fft'),
    uid = require('../uid');

// a component for drawing spectrograms in a canvas element
module.exports = function(){
    // the default window size for the frequency analysis
    var n = 1024 

    var spectrogram = function(){

        var selection = this;

        function draw(){

            var x = spectrogram.x(),
                width = spectrogram.width(),
                height = spectrogram.height();

            selection.each(function(d){
                
                var data = d.channel,
                    buffer = d.buffer,
                    canvas = d3.select(this),
                    drawContext = canvas.node().getContext('2d'),
                    fft = new FFT.complex(n, false),
                    output = new Float32Array(n * 2),
                    lightness = d3.scale.log().range([100,0]).domain([1,480]),
                    alpha = d3.scale.log().range([0,1]).domain([1,480]),
                    frequencyHeight = n/4,
                    y = d3.scale.linear().range([height,0]).domain([0,frequencyHeight]),
                    pixelHeight = height / frequencyHeight;

                this.width = this.width;

                // trim the data to the x domain
                var domain = x.domain();
                data = data.subarray(domain[0] * buffer.sampleRate, domain[1] * buffer.sampleRate + n);

                if (domain[1] > buffer.duration){
                    width = x(buffer.duration)
                }
      
                // i loops through the pixels
                for (var i=0;i<width;i++){
                    var startSample = ~~((data.length - n) / width * i),
                        input = data.subarray(startSample, startSample + n)
                    fft.simple(output, input, 'real');

                    var realOutput = new Float32Array(frequencyHeight);
                    for (var j=0;j<frequencyHeight;j++){
                        realOutput[j] = Math.sqrt(output[j*2]*output[j*2]+output[j*2+1]*output[j*2+1]);
                    }

                    var mean = d3.mean(realOutput),
                        max = 0, maxPosition;

                    for (var j=0;j<frequencyHeight;j++){


                        // output contains complex pairs, so we must just get the
                        // magnitude of each pair
                        var value = realOutput[j];

                        if (value > max){
                            max = value;
                            maxPosition = j;
                        }
 
                        var l = value > 50 ? 100 : lightness(value);

                        drawContext.fillStyle = 'hsla(1, 100%, '+l+'%, '+alpha(value)+')';
                        drawContext.fillRect(i,y(j),1,pixelHeight);
                    }

                    // other optional markings on the spectrogram 

                    // drawContext.fillStyle = 'hsla(90, 50%, 50%, 1)';
                    // drawContext.fillRect(i, height - (mean * 100),2,2);

                    // drawContext.fillStyle = 'hsla(270, 50%, 100%, 1)';
                    // drawContext.fillRect(i, height - (max/2),2,2);

                    // drawContext.fillStyle = 'hsla(90, 50%, 100%, 1)';
                    // drawContext.fillRect(i, y(maxPosition),2,2);
                }
            })
        }

        draw();

        var timeline = spectrogram.timeline();

        if (timeline){
            timeline.on('end', draw)
        }
    }

    // inherit x and buffer properties from the commonProperties
    return d3.rebind(spectrogram, commonProperties(), 'x','height','width','timeline');
}