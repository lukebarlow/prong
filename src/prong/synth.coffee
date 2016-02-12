module.exports = () ->

    context = require('./audioContext')()
    oscillators = []
    
    pitchToFrequency = (pitch) ->
        a = 1.059463094359
        return 440 * Math.pow(a, pitch - 69)

    clearOscillators = ->
        oscillators.forEach ([oscillator, gain]) ->
            oscillator.disconnect()
        oscillators = []

    synth = {}

    synth.playNotes = (currentSequenceTime, notes) ->

        time = (_time) ->
            return _time + context.currentTime - currentSequenceTime

        notes.forEach (note) ->
            frequency = pitchToFrequency(note.pitch)
            scaledVelocity = if 'velocity' of note then note.velocity / 127 else 1

            startTime = time(note.start)
            oscillator = context.createOscillator()
            
            gain = context.createGain()
            oscillator.connect(gain)
            gain.connect(context.destination)
            oscillator.type = 'sine'
            oscillator.frequency.value = frequency
            oscillator.start(startTime)
            oscillator.stop(startTime + note.duration)

            if note.bend
                note.bend.forEach ([t,bend]) ->
                    oscillator.frequency.setValueAtTime(pitchToFrequency(note.pitch + bend), startTime + t)

            volumeCurve = note.volume || [[0,0.5],[note.duration,0.5]]

            gain.gain.value = volumeCurve[0][1] * scaledVelocity

            lastVolume = volumeCurve[0][1]
            volumeCurve.forEach ([t, volume]) ->
                gain.gain.linearRampToValueAtTime(volume * scaledVelocity, startTime + t)
                lastVolume = volume

            # stops note off clicks
            gain.gain.linearRampToValueAtTime(lastVolume * scaledVelocity, startTime + note.duration - 0.01)
            gain.gain.linearRampToValueAtTime(0, startTime + note.duration)

            oscillators.push([oscillator,gain])
            

    synth.stop = ->
        clearOscillators()


    return synth