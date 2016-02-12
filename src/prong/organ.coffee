module.exports = () ->

    context = require('./audioContext')()
    real = new Float32Array([0, 1, 0, 1])
    imaginary = new Float32Array([0, 0, 0, 0])
    isOn = false
    volume = 0

    osc = context.createOscillator()
    osc.frequency.value = 160
    gain = context.createGain()
    osc.connect(gain)
    gain.connect(context.destination)
    gain.gain.value = volume
    osc.start(0)


    setWave = ->
        waveTable = context.createPeriodicWave(real, imaginary)
        osc.setPeriodicWave(waveTable)

    setWave()

    organ = {}


    organ.frequencyComponents = ([_real, _imaginary]) ->
        if not arguments.length then return [real, imaginary]
        real = new Float32Array(_real)
        imaginary = new Float32Array(_imaginary)
        setWave()
        return this


    organ.volume = (_volume) ->
        if not arguments.length then return volume
        volume = _volume
        if isOn
            gain.gain.value = volume
        return this


    organ.on = (_on = true) ->
        if not arguments.length then return isOn
        if _on 
            gain.gain.value = volume
        else
            gain.gain.value = 0
        isOn = _on
        return this


    organ.start = ->
        organ.on(true)
        
    
    organ.stop = ->
        organ.on(false)


    return organ