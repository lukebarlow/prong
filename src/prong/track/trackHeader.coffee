trackName = require('../trackName')
commonProperties = require('../commonProperties')

module.exports = ->

    trackHeader = (selection) ->

        selection
            .attr('class', 'trackHeader')

        selection.append('rect')
            .attr('x', -95)
            .attr('y', 0)
            .attr('width', 95)
            .attr('height', (d) => d.height)

        selection.append('text')
            .attr('x', -5)
            .attr('y', (d) => d.height / 2)
            .attr('text-anchor', 'end')
            .attr('alignment-baseline', 'middle')
            .attr('class', 'trackName')
            .text(trackName)

        closeButton = selection.append('g')
            .attr('transform', (d) => "translate(-80, #{d.height/2})")
            .attr('class', 'closeButton')

        closeButton.append('circle')
            .attr('r', 8)

        closeButton.append('text')
            .attr('text-anchor', 'middle')
            .attr('alignment-baseline', 'middle')
            .text('x')

        closeButton.on 'click', (d) => 
            trackHeader.sequence().removeTrack(d)
            #console.log('remove track', d)

    return d3.rebind(trackHeader, commonProperties(), 'sequence')