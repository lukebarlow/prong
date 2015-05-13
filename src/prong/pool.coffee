###
A non-visual component which keeps track of a number of audio resources,
typically when these are shared by different regions in a track
###

sound = require('./sound').sound
async = require('async')

module.exports = (_clips) ->

    clips = _clips
    urls = clips.map((r) -> r.src)
    pool = {}
    loaded = false
    loadCallbacks = []

    pool.getClipById = (id, callback) ->
        clip = clips.filter((r) -> r.id == id)
        
        if clip.length != 1
            throw (if clip.length then "Pool clip id not unique" else "Pool clip id not found")

        else
            clip = clip[0]

            # if it's already loaded, then return that buffer
            if clip._buffer
                callback(clip)
            # if it's already loading, then we add our callback to the list
            # of things that want to know when loading is finished
            else if clip._loading
                clip._loadCallbacks.push(callback)
            # otherwise initiate loading it
            else
                clip._loading = true
                clip._loadCallbacks = []
                sound clip.src, (buffer) ->
                    clip._buffer = buffer
                    clip._channel = buffer.getChannelData(0)
                    clip._loading = false
                    if clip._loadCallbacks
                        clip._loadCallbacks.forEach (cb) ->
                            cb(clip)
                    callback(clip)
        
    
    pool.clips = ->
        loaded = false
        return clips


    return pool