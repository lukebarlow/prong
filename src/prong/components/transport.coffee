commonProperties = require('../commonProperties')
playStopButton = require('./playStopButton')
d3 = require('d3-prong')

# a simple transport bar for prong sequences, with buttons for starting and
# stopping
module.exports = ->

    transport = (selection) ->
        playStop = playStopButton().on 'change', (playing) ->
            sequence = transport.sequence()
            if not sequence then return
            if playing
                sequence.play()
            else
                if sequence.playing()
                    sequence.stop()
                else
                    sequence.currentTime(0)

        selection.append('div').call(playStop)

        if transport.sequence()
            updatePlayState = () -> 
                playStop.playing(transport.sequence().playing())

            transport.sequence().on('play', updatePlayState)
            transport.sequence().on('stop', updatePlayState)

    return d3.rebind(transport, commonProperties(), 'sequence')