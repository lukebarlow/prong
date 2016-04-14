d3 = require('d3-prong')
commonProperties = require('../commonProperties')
video = require('./video')
audio = require('./audio')
text = require('./text')
audioRegions = require('./audioRegions')
uid = require('../uid')

# the mapping from track type strings to component constructor functions
trackTypeMappings = {
    'audio' : audio,
    'audioRegions' : audioRegions,
    'video' : video,
    'text' : text
}

# the mapping from file endings to track type strings
fileTypesToTrackTypes = {
    'mp3' : 'audio',
    'wav' : 'audio',
    'm4a' : 'audio',
    'mp4' : 'video',
    'ogg' : 'video' # confusing. ogg can be just audio
}

# creates a mapping of track types to component objects, which are later used
# to render the tracks
createComponents = (tracks, sequence, dispatch) ->
    components = {}
    for track in tracks
        if not track.type then track.type = 'audio'
        if not (track.type of components) # one component for each track type
            component = trackTypeMappings[track.type]().sequence(sequence)
            if 'on' of component
                # forward the load event, if applicable
                component.on('load', dispatch.load)
            components[track.type] = component
    return components


setTrackKeys = (tracks) ->
    for track in tracks
        if not ('key' of track)
            track.key = uid()


# if tracks are the same type (i.e. map to the same component) and the component
# has the attribute canBeGrouped = true, then the track data will be grouped
# together so that a single component can draw several adjacent tracks in one
# operation
groupTracks = (tracks, components) ->

    setTrackKeys(tracks)

    lastComponent = null
    lastTrack = null
    groupedTracks = []

    for track in tracks
        component = components[track.type]
        if lastComponent and lastComponent == component and component.canBeGrouped
            lastTrack.push(track)
            lastTrack.key += '-' + track.key
        else
            if component.canBeGrouped
                group = [track]
                group.type = track.type
                groupedTracks.push(group)
                lastTrack = group
                lastTrack.key = track.key
            else
                groupedTracks.push(track)
                lastTrack = track
        lastComponent = component

    return groupedTracks



module.exports = ->    
    dispatch = d3.dispatch('load')

    track = (selection, options) ->
        tracks = selection.datum()

        components = createComponents(tracks, track.sequence(), dispatch)
        groupedTracks = groupTracks(tracks, components)

        join = selection.selectAll('.track')
            .data(groupedTracks, (d) => d.key)
            
        newTracks = join.enter()
            .append('div')
            .attr('class','track')

        newTracks.each (d,i) ->
            sel = d3.select(this)         
            components[d.type](sel, options)

        join.exit()
            .each (d, i) =>
                d.dead = true # TODO : build this feature into omniscience,
                              # so that when an object is orphaned from the
                              # tree it sends out a death cry event
            .remove()

    track.on = (type, listener) ->
        dispatch.on(type, listener)

    return d3.rebind(track, commonProperties(), 'sequence')


module.exports.registerTrackType = (type, component) ->
    trackTypeMappings[type] = component


module.exports.unpackTrackData = (tracks) ->
    tracks.forEach (track, i) ->
        if typeof(track) == 'string'
            fileType = track.split('.').pop()
            trackType = fileTypesToTrackTypes[fileType]
            tracks[i] = {
                src : track,
                type : trackType
            }