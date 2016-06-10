commonProperties = require('../commonProperties')
playStopButton = require('./playStopButton')
d3 = require('d3-prong')
uid = require('../uid')
resolveElement = require('../resolveElement')

# a simple transport bar for prong sequences, with buttons for starting and
# stopping
module.exports = ->

    transport = (selection) ->
        selection = resolveElement(selection)

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

        selection.html('').append('div').call(playStop)

        if transport.sequence()
            updatePlayState = () -> 
                playStop.playing(transport.sequence().playing())

            transport.sequence().on('play.transport' + uid(), updatePlayState)
            transport.sequence().on('stop.transport' + uid(), updatePlayState)


    transport.draw = transport

    return d3.rebind(transport, commonProperties(), 'sequence')