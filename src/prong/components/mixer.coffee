slider2 = require('./slider2')
pot = require('./pot')
trackName = require('../')

module.exports = ->

    sequence = null

    volumeSlider = slider2()
        .domain([0,100])
        .size(100)
        .breadth(40)
        .format(d3.format('f'))
        .key('volume')
        .horizontal(false)

    panPot = pot()
        .domain([-64,+63])
        .radius(20)
        .key('pan')
        .format(d3.format('d'))

    margin = {top: 40, right: 40, bottom: 40, left: 40}
    width = 1200 - margin.left - margin.right
    height = 250 - margin.bottom - margin.top


    mixer = (selection) ->

        tracks = sequence.tracks().filter (track) -> 
            track.type in ['audio','audioRegions']

        svg = selection.append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", 
                    "translate(" + margin.left + "," + margin.top + ")")

        draw = ->
            svg.selectAll('g').remove()
            strips = svg.selectAll('g')
                .data(tracks)
                .enter()
                .append('g')
                .attr 'transform', (d,i) ->
                    return 'translate(' + i*80 + ',0)'
                .on 'mouseover', (d) ->
                    d3.select(this).classed('over', true)
                    d.over = true;
                .on 'mouseout',  (d) ->
                    d3.select(this).classed('over', false)
                    d.over = false
                .each (d) ->
                    thiz = d3.select(this)
                    d.watch('over', -> thiz.classed('over', d.over) )

            strips.append('g').call(panPot)
            strips.append('g').attr('transform', 'translate(-20,50)')
                .call(volumeSlider);
            strips.append('text')
                .attr('transform', 'translate(0, 190)')
                .attr('text-anchor', 'middle')
                .text(prong.trackName)
        
        draw()

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




    mixer.sequence = (_sequence) ->
        if not arguments.length
            return sequence
        sequence = _sequence
        return mixer




    return mixer
