d3 = require('d3-prong')


module.exports = ->

    drawbars = 33
    decimalPlaces = 3
    width = 600
    height = 400
    dispatch = d3.dispatch('change')
    drawbarData = d3.range(drawbars).map((i) -> {magnitude: 0, phase: 0})
    selection = null
    ignorePhase = false

    makeSlider = (key) ->
        return 

    magnitudeSlider = prong.slider()
        .domain([0, 1])
        .height(height / 3 * 2 - 5)
        .key('magnitude')
        .exponent(0.2)
        .format(d3.format('.3f'))

    phaseSlider = prong.slider()
        .domain([-Math.PI, Math.PI])
        .height(height / 3 - 5)
        .key('phase')
        .format(d3.format('.2f'))

    sliderChangeHandler = ->
        dispatch.change(organController.frequencyComponents())

    magnitudeSlider.on('change', sliderChangeHandler)
    phaseSlider.on('change', sliderChangeHandler)


    organController = (_selection) ->

        if _selection
            selection = _selection

        widthPerDrawbar = width / drawbars
        magnitudeSlider.width(widthPerDrawbar - 1)
        phaseSlider.width(widthPerDrawbar - 1)

        g = selection.selectAll('g')
            .data(drawbarData)
            .enter()
            .append('g')
            .attr('transform', (d, i) -> "translate(#{i*widthPerDrawbar+2},10)")
            .classed('black', (d, i) ->
                if i == 0 then return true
                while i > 1
                    i = i / 2.0
                return Math.round(i) != i
            )

        g.append('g').call(magnitudeSlider)
        g.append('g')
            .attr('transform', "translate(0,#{height * 2 / 3})")
            .call(phaseSlider)


    organController.frequencyComponents = (components) ->
        if not arguments.length 
            if ignorePhase
                real = drawbarData.map (d) -> d.magnitude
                imag = real.map (d) -> 0
            else
                real = drawbarData.map (d) -> Math.cos(d.phase) * d.magnitude
                imag = drawbarData.map (d) -> Math.sin(d.phase) * d.magnitude
            return [real, imag]

        [_real, _imag] = components

        if _real.length != _imag.length
            throw new Exception('Must have the same number of real and imaginary components')

        drawbarData = _real.map (_, i) -> 
            real = _real[i]
            imag = _imag[i]
            magnitude = Math.sqrt(real * real + imag * imag)
            phase = Math.atan2(imag, real)
      
            return {magnitude : magnitude, phase : phase}

        drawbars = drawbarData.length

        if selection
            selection.html('')
            organController()

        sliderChangeHandler()

        return this


    organController.drawbarData = (_drawbarData) ->
        if not arguments.length then return drawbarData
        drawbarData = _drawbarData
        drawbars = drawbarData.length
        sliderChangeHandler()
        return organController


    organController.width = (_width) ->
        if not arguments.length then return width
        width = _width
        return organController


    organController.height = (_height) ->
        if not arguments.length then return height
        height = _height
        magnitudeSlider.height(height / 3 * 2 - 5)
        phaseSlider.height(height / 3 - 5)
        return organController


    organController.on = (type, listener) ->
        dispatch.on(type, listener)
        return organController


    organController.ignorePhase = (_ignorePhase) ->
        if not arguments.length then return ignorePhase
        ignorePhase = _ignorePhase
        sliderChangeHandler()



    return organController