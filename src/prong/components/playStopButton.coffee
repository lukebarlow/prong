d3 = require('../d3-prong-min')

module.exports = ->

    width = 50
    height = width
    playing = false

    dispatch = d3.dispatch('change')

    playStopButton = (selection) ->

        svg = selection.append('svg').attr('class','playStopButton')
            .attr('height',height)
            .attr('width',width)

        g = svg.append('g')
            .attr('transform',"translate(#{width/2},#{height/2})")

        button = g.append('circle')
            .attr('cx', 0)
            .attr('cy', 0)
            .attr('r', width / 2)

        triangleRadius = width / 3
        top = triangleRadius * Math.sin(Math.PI * 2 / 3)
        left = triangleRadius * Math.cos(Math.PI * 2 / 3)

        play = g.append('polygon')
            .attr('points',"#{triangleRadius},0 #{left},#{top} #{left},#{0-top}")

        squareRadius = width / 4

        stop = g.append('rect')
            .attr('x', 0-squareRadius + 'px')
            .attr('y', 0-squareRadius + 'px')
            .attr('width', squareRadius * 2)
            .attr('height', squareRadius * 2)
            .style('display','none')

        setDisplay = ->
            play.style('display',if playing then 'none' else 'block')
            stop.style('display',if playing then 'block' else 'none')

        g.on 'click', ->
            playing = !playing
            setDisplay()
            dispatch.change(playing)


        playStopButton.playing = (_playing) ->
            if not arguments.length then return playing
            playing = _playing
            setDisplay()
            return playStopButton


    playStopButton.on = (type, listener) ->
        dispatch.on(type, listener)
        return playStopButton


    return playStopButton
            