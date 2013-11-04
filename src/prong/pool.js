/*
A non-visual component which keeps track of a number of audio resources,
especially when these are shared by different regions in a track
*/

var sound = require('./sound').sound,
    async = require('async');

module.exports = function(_resources){

    var resources = _resources,
        urls = resources.map(function(r){return r.src}),
        pool = {},
        loaded = false,
        loadCallbacks = [];

    pool.getBufferForId = function(id, callback){
        var resource = resources.filter(function(r){
            return r.id == id
        });
        if (resource.length == 1){
            var resource = resource[0];
            if (resource.buffer){
                callback(resource.buffer);
            // if it's already loading, then we add our callback to the list
            // of things that want to know when loading is finished
            }else if (resource._loading){
                resource._loadCallbacks.push(callback)
            }else{
                resource._loading = true;
                resource._loadCallbacks = [];
                sound(resource.src, function(buffer){
                    resource.buffer = buffer;
                    resource._loading = false;
                    if (resource._loadCallbacks){
                        resource._loadCallbacks.forEach(function(cb){
                            cb(resource.buffer)
                        })
                    }
                    callback(resource.buffer)
                });
            }
        }else{
            throw resource.length ? "Pool resource id not unique" : "Pool resource id not found"
        }
    }

    pool.resources = function(){
        loaded = false;
        return resources;
    }

    return pool;

}