d3 = require('d3-prong')


module.exports = ->

    drawbars = 65
    decimalPlaces = 3
    width = 600
    height = 300
    dispatch = d3.dispatch('change')
    drawbarData = d3.range(drawbars).map((i) -> {real: 0, imag: 0})
    selection = null

    makeSlider = (key) ->
        return prong.slider()
            .domain([-1, 1])
            .height(height / 2 - 5)
            .key(key)
            .exponent(0.2)
            .format(d3.format('.3f'))

    realSlider = makeSlider('real')
    imagSlider = makeSlider('imag')

    sliderChangeHandler = ->
        dispatch.change(organController.frequencyComponents())

    realSlider.on('change', sliderChangeHandler)
    imagSlider.on('change', sliderChangeHandler)


    organController = (_selection) ->

        if _selection
            selection = _selection

        widthPerDrawbar = width / drawbars
        realSlider.width(widthPerDrawbar - 1)
        imagSlider.width(widthPerDrawbar - 1)

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

        g.append('g').call(realSlider)
        g.append('g')
            .attr('transform', "translate(0,#{height / 2})")
            .call(imagSlider)


    organController.frequencyComponents = (components) ->
        if not arguments.length 
            real = drawbarData.map (d) -> d.real
            imag = drawbarData.map (d) -> d.imag
            return [real, imag]

        [_real, _imag] = components

        if _real.length != _imag.length
            throw new Exception('Must have the same number of real and imaginary components')

        drawbarData = _real.map (_, i) -> 
            {real: _real[i], imag: _imag[i]}

        drawbars = drawbarData.length

        if selection
            selection.html('')
            organController()

        sliderChangeHandler()

        return this


    #organController.magnitudeAndPhase = ([_mag, _phase]) ->



    organController.width = (_width) ->
        if not arguments.length then return width
        width = _width
        return organController


    organController.on = (type, listener) ->
        dispatch.on(type, listener)
        return organController


    return organController