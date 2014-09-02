# records the positions of faders and pots as named presets. gui allows you
# to easily flip between them

module.exports = ->

    presets = null
    mixer = null

    mixPresets = (selection) ->
        selection.selectAll('div')
            .data(presets)
            .enter()
            .append('button')
            .html (d) -> d.name
            .on 'click', (d) ->
                mixer.loadPreset(d, 500)


    mixPresets.mixer = (_mixer) ->
        if not arguments.length
            return mixer
        mixer = _mixer
        return mixPresets


    mixPresets.presets = (_presets) ->
        if not arguments.length
            return presets
        presets = _presets
        return mixPresets


    return mixPresets