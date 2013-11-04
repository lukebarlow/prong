/*
Allows you to watch a parent object, and receive event notifications when
any property changes on any property of the object, or any property of any
child object, all the way down the tree of descendants.
*/


/* 
This object.watch code is borrowed from https://gist.github.com/eligrey/384583,
with some modifications, mainly to allow multiple handlers on a single
property. This enables us to receive events when properties
change on objects
*/
if (!Object.prototype.watch) {

    Object.defineProperty(Object.prototype, 'watch', {
        enumerable: false,
        configurable: true,
        writable: false,
        value: function (prop, handler) {

            if (!this.hasOwnProperty('_watchHandlers')){
                Object.defineProperty(this, '_watchHandlers', {
                    enumerable : false,
                    configurable : false,
                    writable : false,
                    value : {}
                })
            }

            var watchHandlers = this._watchHandlers;
            if (!(prop in watchHandlers)){
                watchHandlers[prop] = []
            }
            watchHandlers[prop].push(handler);
            var thiz = this;

            var oldval = this[prop],
                newval = oldval,
                getter = function () {
                    return newval;
                },
                setter = function (val) {
                    oldval = newval;
                    newval = val;
                    if (newval != oldval){
                        thiz._watchHandlers[prop].forEach(function(handler){
                            handler.call(thiz, prop, oldval, val);
                        })
                    }
                    return val;
                };
            
            if (delete this[prop]) { // can't watch constants
                Object.defineProperty(this, prop, {
                    get: getter,
                    set: setter,
                    enumerable: true,
                    configurable: true
                });
            }
        }
    });
}
 
// object.unwatch
if (!Object.prototype.unwatch) {
    Object.defineProperty(Object.prototype, 'unwatch', {
            enumerable: false,
            configurable: true,
            writable: false,
            value: function (prop) {
                var val = this[prop];
                delete this[prop]; // remove accessors
                this[prop] = val;
            }
    });
}

/* walk all the descendants of the parent[key] object, calling the callback
for each one. The path argument is simply passed on to the callback
*/
function walk(parent, key, callback, path){

    if (!path){
        path = key
    }else{
        path += ',' + key;
    }

    callback(parent, key, path);
    
    if (typeof(parent[key]) == 'object'){
         Object.keys(parent[key]).forEach(function(_key){
            walk(parent[key], _key, callback, path)
        })
    }
}

function getObjectFromPath(parent, path){
    var current = parent;
    path.forEach(function(prop){
        current = current[prop]
    })
    return current;
}

module.exports =  function(parent, key){
    var omniscience = {},
        dispatch = d3.dispatch('propertyChange');

    function setupWatches(parent, key, path){
        walk(parent, key, function(_parent, _key, path){
            _parent.watch(_key, function(property, oldValue, newValue){
                changeHandler(path.split(','), newValue, oldValue)
            })
        }, path)
    }

    setupWatches(parent, key);

    function changeHandler(path, newValue, oldValue){
        // if the new value is an object, then we need to set up new watches
        // on it
        if (typeof(newValue) == 'object'){
            var p = getObjectFromPath(parent, path);
            Object.keys(p).forEach(function(k){
                setupWatches(p, k, path.join(','))
            })

            // TODO : unwatch the old value?
        }

        dispatch.propertyChange(parent, path, newValue, oldValue);
        path.slice(1)
    }

    /* for attaching event listeners to this omniscience object */
    omniscience.on = function(type, listener){
        dispatch.on(type, listener)
        return omniscience;
    }

    return omniscience;
}