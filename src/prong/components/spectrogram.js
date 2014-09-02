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
                
                var data = d._channel,
                    buffer = d._buffer,
                    canvas = d3.select(this),
                    drawContext = canvas.node().getContext('2d'),
                    fft = new FFT.complex(n, false),
                    output = new Float32Array(n * 2),
                    lightness = d3.scale.log().range([100,0]).domain([1,480]),
                    alpha = d3.scale.log().range([0,1]).domain([1,480]),
                    frequencyHeight = n/12,
                    y = d3.scale.linear().range([height,0]).domain([0,frequencyHeight/2]),
                    pixelHeight = height / frequencyHeight;

                this.width = this.width;

                // trim the data to the x domain
                var domain = x.domain();
                var overallStartSample = Math.round(domain[0] * buffer.sampleRate) - 1,
                    overallEndSample = Math.round(domain[1] * buffer.sampleRate) - 1;

                data = data.subarray(overallStartSample, overallEndSample + n);

                if (domain[1] > buffer.duration){
                    width = x(buffer.duration)
                }
      
                // i loops through the pixels
                for (var i=0;i<width;i ++){
                    var startSample = ~~((data.length - n) / width * i),
                        input = data.subarray(startSample, startSample + n)
                    fft.simple(output, input, 'real');

                    //console.log('start sample', overallStartSample + startSample);

                    var realOutput = new Float32Array(frequencyHeight);
                    for (var j=0;j<frequencyHeight;j++){
                        realOutput[j] = Math.sqrt(output[j*2]*output[j*2]+output[j*2+1]*output[j*2+1]);
                    }

                    var mean = d3.mean(realOutput),
                        max = 0, maxPosition;

                    var time = (overallStartSample + startSample) / buffer.sampleRate;

                    for (var j=0;j<frequencyHeight;j++){

                        // output contains complex pairs, so we must just get the
                        // magnitude of each pair
                        var value = realOutput[j];

                        if (value > max){
                            max = value;
                            maxPosition = j;
                        }
 
                        var l = value > 80 ? 100 : lightness(value);

                        drawContext.fillStyle = 'hsla(1, 100%, '+l+'%, '+alpha(value)+')';
                        drawContext.fillRect(i,y(j),1,pixelHeight*2);
                    }

                    var significants = realOutput.map(function(d){
                        return d > 50 ? d : 0
                    }) 

                    var totalMoment = d3.sum(significants, function(d,i){
                        return d * i;
                    })

                    var totalWeight = d3.sum(significants)
                    var centreOfGravity = totalMoment / totalWeight;

                    if (max > 50){
                        drawContext.fillStyle = 'hsla(120, 100%, 50%, 1)';
                        drawContext.fillRect(i, y(centreOfGravity),10,2);
                    }
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

// figures out a 
function weightedAverage(){

}
