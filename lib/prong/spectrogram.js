var pool = pool || {}

// a component for drawing spectrograms in a canvas element
pool.spectrogram = function(){
    // the default window size for the frequency analysis
    var n = 1024 

    var spectrogram = function(){
        var x = spectrogram.x()
        var buffer = spectrogram.buffer()
        var canvas = this
        var width = parseInt(canvas.attr('width'))
        var height = parseInt(canvas.attr('height'))
        var drawContext = canvas.node().getContext("2d");
        // using the fft library from
        var fft = new FFT.complex(n, false);
        var output = new Float32Array(n * 2)
        var lightness = d3.scale.log().range([100,0]).domain([1,480])
        var alpha = d3.scale.log().range([0,1]).domain([1,480])
        var y = d3.scale.linear().range([128,0]).domain([0,n/6])
        var samplesPerFft = ~~(buffer.length / width)
        // for now, we just take the first channel of multi-channel data
        var data = buffer.getChannelData(0)

        for (var i=0;i<data.length-n;i+=samplesPerFft){
            var input = data.subarray(i, i + n)
            fft.simple(output, input, 'real')
            for (var j=0;j<n/6;j++){
                // output contains complex pairs, so we must just get the
                // magnitude of each pair
                var value = Math.sqrt(output[j*2]*output[j*2]+
                    output[j*2+1]*output[j*2+1])
                drawContext.fillStyle = 'hsla(1, 50%, '+lightness(value)+'%, '+alpha(value)+')'
                drawContext.fillRect(x(i/buffer.sampleRate),y(j),1,5)
            }
        }
    }

    // inherit x and buffer properties from the commonProperties
    return d3.rebind(spectrogram, pool.commonProperties(), 'x', 'buffer');
}