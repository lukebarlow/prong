var d3 = require('d3-prong')
var uid = require('./uid')

function beginsWithUnderscore(s){
    return s.slice(0,1) == '_'
}

function makeWatchable(o){
    
    if (o._watchable){
        return o
    }

    var dispatch = d3.dispatch('change', 'syncChange')
    var timeout = null

    function fireChangeAtEndOfThread(){
        dispatch.syncChange()
        if (timeout == null){
            timeout = setTimeout(function(){
                timeout = null
                dispatch.change()
            }, 0)
        }
    }

    var handler = {
        set: function(target, key, value, receiver){
            var hidden = beginsWithUnderscore(key)
            if (hidden){
                target[key] = value
                return
            }
            var changed = (target[key] != value)
            var alreadyExisted = key in target
            var valueIsObject = typeof(value) == 'object'
            // if a new object property is added, then watch that too
            if (valueIsObject && !alreadyExisted && !hidden){
                value = makeWatchable(value)
                value._on('syncChange.' + uid(), function(){
                    fireChangeAtEndOfThread()
                })
            }
            target[key] = value
            if (changed && !hidden){
                fireChangeAtEndOfThread()
            }
            return true
        }
    }

    var proxy = new Proxy(o, handler)
    proxy._on = function(type, handler){
        dispatch.on(type, handler)
    }

    proxy.sort = function(){
        Array.prototype.sort.apply(o, arguments)
    }
    
    Object.keys(o).forEach(function(key){

        if (!beginsWithUnderscore(key) && typeof(o[key]) == 'object'){
            o[key] = makeWatchable(o[key])
            o[key]._on('syncChange.' + uid(), function(){
                fireChangeAtEndOfThread()
            })
        }
    })

    proxy._watchable = true
    return proxy
}


function watch(o, changeHandler){
    if (!o._watchable){
        o = makeWatchable(o)
    }
    o._on('change.' + uid(), changeHandler)
    return o
}

module.exports = { 
    watch : watch,
    makeWatchable : makeWatchable
}