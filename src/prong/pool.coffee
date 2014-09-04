###
A non-visual component which keeps track of a number of audio resources,
typically when these are shared by different regions in a track
###

sound = require('./sound').sound
async = require('async')

module.exports = (_resources) ->

    resources = _resources
    urls = resources.map((r) -> r.src)
    pool = {}
    loaded = false
    loadCallbacks = []

    pool.getBufferForId = (id, callback) ->
        resource = resources.filter((r) -> r.id == id)
        
        if resource.length != 1
            throw (if resource.length then "Pool resource id not unique" else "Pool resource id not found")

        else
            resource = resource[0]

            # if it's already loaded, then return that buffer
            if resource.buffer
                callback(resource.buffer)
            # if it's already loading, then we add our callback to the list
            # of things that want to know when loading is finished
            else if resource._loading
                resource._loadCallbacks.push(callback)
            # otherwise initiate loading it
            else
                resource._loading = true
                resource._loadCallbacks = []
                sound resource.src, (buffer) ->
                    resource.buffer = buffer
                    resource._loading = false
                    if resource._loadCallbacks
                        resource._loadCallbacks.forEach (cb) ->
                            cb(resource.buffer)
                    callback(resource.buffer)
        
    
    pool.resources = ->
        loaded = false
        return resources


    return pool