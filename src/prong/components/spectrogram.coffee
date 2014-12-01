commonProperties = require('../commonProperties')
FFT = require('fft')
uid = require('../uid')
d3 = require('../d3-prong-min')

# a component for drawing spectrograms in a canvas element
module.exports = ->
    # the default window size for the frequency analysis
    n = 1024 

    spectrogram = ->

        selection = this

        draw = ->

            x = spectrogram.x()
            width = spectrogram.width()
            height = spectrogram.height()

            selection.each (d) ->
                
                data = d._channel
                buffer = d._buffer
                canvas = d3.select(this)
                drawContext = canvas.node().getContext('2d')
                fft = new FFT.complex(n, false)
                output = new Float32Array(n * 2)
                lightness = d3.scale.log().range([100,0]).domain([1,480])
                alpha = d3.scale.log().range([0,1]).domain([1,480])
                frequencyHeight = n / 12
                y = d3.scale.linear().range([height,0]).domain([0,frequencyHeight/2])
                pixelHeight = height / frequencyHeight

                this.width = this.width

                # trim the data to the x domain
                domain = x.domain()
                overallStartSample = Math.max(Math.round(domain[0] * buffer.sampleRate) - 1, 0)
                overallEndSample = Math.round(domain[1] * buffer.sampleRate) - 1

                data = data.subarray(overallStartSample, overallEndSample + n)


                if domain[1] > buffer.duration
                    width = x(buffer.duration)
                
      
                # i loops through the pixels
                for i in [0...width]
                    startSample = ~~((data.length - n) / width * i)
                    input = data.subarray(startSample, startSample + n)
                    fft.simple(output, input, 'real')

                    #console.log('start sample', overallStartSample + startSample);

                    realOutput = new Float32Array(Math.round(frequencyHeight))
                    for j in [0...frequencyHeight]
                        realOutput[j] = Math.sqrt(output[j*2]*output[j*2]+output[j*2+1]*output[j*2+1])
                    
                    mean = d3.mean(realOutput)
                    max = 0
                    maxPosition = null

                    time = (overallStartSample + startSample) / buffer.sampleRate

                    for j in [0...frequencyHeight]

                        # output contains complex pairs, so we must just get the
                        # magnitude of each pair
                        value = realOutput[j]

                        if value > max
                            max = value
                            maxPosition = j
                        
                        l = if value > 80 then 100 else lightness(value)

                        drawContext.fillStyle = "hsla(1, 100%, #{l}%, #{alpha(value)})"
                        drawContext.fillRect(i, y(j), 1, pixelHeight * 2)
                    

                    significants = realOutput.map (d) -> if d > 50 then d else 0
                    totalMoment = d3.sum(significants, (d,i) -> d * i)
                    totalWeight = d3.sum(significants)
                    centreOfGravity = totalMoment / totalWeight

                    if max > 50
                        drawContext.fillStyle = 'hsla(120, 100%, 50%, 1)'
                        drawContext.fillRect(i, y(centreOfGravity), 10, 2)
                    
        draw()
        timeline = spectrogram.timeline()

        if timeline
            timeline.on('end', draw)
        
        
    # inherit x and buffer properties from the commonProperties
    return d3.rebind(spectrogram, commonProperties(), 'x','height','width','timeline')

