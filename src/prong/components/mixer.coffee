d3 = require('d3-prong')
slider = require('./slider')
pot = require('./pot')
omniscience = require('omniscience')
trackName = require('../trackName')
resolveElement = require('../resolveElement')

module.exports = ->

    sequence = null
    showPan = true
    showVolume = true
    idsOnLastDraw = null
    showTrackNames = true

    volumeSlider = slider()
        .domain([0,100])
        .height(100)
        .width(34)
        .format(d3.format('f'))
        .key('volume')
        .horizontal(false)
        .circleStyle(true)

    panPot = pot()
        .domain([-64,+63])
        .radius(0)
        .key('pan')
        .format(d3.format('d'))


    idsKey = =>
        (sequence.tracks().map (t) => t.id).join(':')


    mixer = (selection) ->

        selection = resolveElement(selection)
        margin = {top: 40, right: 0, bottom: 40, left: 40}
        height = (if showPan then 50 else 0) + (if showVolume then 140 else 0) + 30

        height += if showTrackNames then 30 else 0
        height = height - margin.bottom - margin.top

        svg = selection.append('svg')
            .attr('height', height + margin.top + margin.bottom)
            .append('g')
            .attr('transform', "translate(#{margin.left}, #{margin.top})")

        draw = ->
            key = idsKey()
            if key == idsOnLastDraw
                return
            idsOnLastDraw = key

            width = (sequence.tracks().length + 1) * 50

            d3.select(svg.node().parentElement)
                .attr("width", width + margin.left + margin.right)

            tracks = sequence.tracks().filter (track) -> 
                track.type in ['audio','audioRegions']

            join = svg.selectAll('g.channelStrip')
                .data(tracks, (track) => track.id)

            join.transition()
                .duration(500)
                .attr 'transform', (d,i) ->
                    return 'translate(' + (i * 50) + ',0)'

            enter = join.enter()

            newlyAdded = enter.append('g')
                .attr('class', 'channelStrip')
                .attr 'transform', (d,i) ->
                    return 'translate(' + (i * 50) + ',0)'
                .on 'mouseover', (d) ->
                    #d3.select(this).classed('over', true)
                    d.over = true;
                .on 'mouseout',  (d) ->
                    #d3.select(this).classed('over', false)
                    d.over = false
                .each (d) ->
                    thiz = d3.select(this)
                    d.on 'change', =>
                        thiz.classed('over', d.over)                        

            join.exit().remove()

            y = 0 # keeps track of component vertical

            if showPan
                newlyAdded.append('g').call(panPot)
                y += 50

            if showVolume
                newlyAdded.append('g')
                    .attr('transform', "translate(-17,#{y})")
                    .call(volumeSlider);
                y += 140

            newlyAdded.append('text')
                .attr('transform', "translate(0, #{y})")
                .attr('text-anchor', 'middle')
                .text(trackName)
                .attr('class', 'trackName')
        
        draw()

        sequence.tracks().on('change', draw)
        # console.log('watching the tracks')
        # omniscience.watch(sequence.tracks(), () =>
        #     draw()
        # )

        mixer.loadPreset = (preset, duration) ->
            for track in tracks
                setting = null
                if track.id of preset.settings
                    setting = preset.settings[track.id]
                else if '_default' of preset.settings
                    setting = preset.settings['_default']
                if not setting
                    continue

                if 'volume' of setting
                    track._startVolume = track.volume
                    track._deltaVolume = setting.volume - track.volume
                if 'pan' of setting
                    track._targetPan = setting.pan
                    track._deltaPan = setting.pan - track.pan


            d3.timer (elapsed) ->
                position = elapsed / duration
                if position > 1 then position = 1
                for track in tracks
                    if '_deltaVolume' of track
                        track.volume = track._startVolume + (track._deltaVolume * position)
                    if '_deltaPan' of track
                        track.pan = track._startPan + (track._deltaPan * position)
                return position == 1


    mixer.draw = mixer

    mixer.sequence = (_sequence) ->
        if not arguments.length
            return sequence
        sequence = _sequence
        return mixer


    mixer.showPan = (_showPan) ->
        if not arguments.length then return showPan
        showPan = _showPan
        return mixer


    mixer.showVolume = (_showVolume) ->
        if not arguments.length then return showVolume
        showVolume = _showVolume
        return mixer


    return mixer