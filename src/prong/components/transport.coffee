commonProperties = require('../commonProperties')
playStopButton = require('./playStopButton')

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

        transport.sequence().on 'play', (playing) ->
            playStop.playing(transport.sequence().playing())


    return d3.rebind(transport, commonProperties(), 'sequence')