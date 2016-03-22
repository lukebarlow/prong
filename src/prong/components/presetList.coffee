commonProperties = require('../commonProperties')
History = require('../history/history')
d3 = require('d3-prong')

module.exports = ->

    presets = []
    dispatch = d3.dispatch('change')
    selected = null
    join = null
    history = null

    updateSelected = =>
        if join
            join.classed('selected', (d) => d == selected)
    

    setVolumesForPreset = (sequence, preset) =>
        if  preset.volumes            
            for track in sequence.tracks()
                volume = preset.volumes[track.trackId]
                if volume.points
                    track.automation = {volume : volume}
                else if volume != undefined
                    track.volume = volume
                    track.automation = null

    getPresetByName = (presetName) =>
        match = presets.filter (p) => p.name == presetName
        if match.length
            return match[0]
        return null

    presetList = (_selection) =>

        selection = _selection

        createHistory = ->
            #debugger
            if not(historyKey = presetList.historyKey()) then return
            history = History(historyKey)

            history.on 'change', (presetName) =>
                if preset = getPresetByName(presetName)
                    selected = preset
                    updateSelected()
                    if sequence = presetList.sequence()
                        setVolumesForPreset(sequence, selected)


        createHistory()

        draw = ->
            if history and selectedName = history.get()
                if preset = getPresetByName(selectedName)
                    selected = preset
                    if sequence = presetList.sequence()
                        setVolumesForPreset(sequence, selected)

            selection.selectAll('div.preset').remove()
            join = selection.selectAll('div.preset')
                .data(presets)
            
            name = (d) => d.name

            join.enter()
                .append('div')
                .attr('class', 'preset')
                .classed('selected', (d) => d == selected)
                .text(name)
                .on 'click', (d) =>
                    if (d != selected)
                        selected = d
                        updateSelected()
                        if sequence = presetList.sequence()
                            setVolumesForPreset(sequence, d)
                        if history
                            history.set(d.name)
                        dispatch.change(d)
            #join.text(name)
            #join.exit().remove()

            selection.selectAll('div.preset.new').remove()

            selection.append('div')
                .attr('class', 'preset new')
                .text('new mix')
                .on 'click', =>
                    newName = window.prompt('Name for your new mix')
                    if not newName
                        return
                    if selected
                        newMix = JSON.parse(JSON.stringify(selected))
                        newMix.name = newName
                    else
                        newMix = {
                            name : newName,
                            globalVolume : 100
                        }
                    presets.push(newMix)
                    selected = newMix
                    if history
                        history.set(selected.name)
                    draw()

        draw()


    presetList.presets = (_presets) =>
        if not arguments.length then return presets
        presets = _presets
        selected = presets[0] # default to selecting the first one
        return presetList
    

    presetList.selected = (_selected) =>
        if not arguments.length then return selected
        selected = _selected
        updateSelection()
        return presetList


    presetList.on = (type, listener) =>
        dispatch.on(type, listener)
        return presetList
        

    return d3.rebind(presetList, commonProperties(), 'sequence', 'historyKey')