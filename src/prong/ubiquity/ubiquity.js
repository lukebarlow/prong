/*
Easy syncing over socket.io of arbitrary JavaScript objects
*/

var omniscience = require('./omniscience'),
    history = require('../history/history'),
    guid = require('../guid');

module.exports = function(parent, key, ignoreList, namespace){

    var socket, 
        roomHistory, 
        room, 
        dispatch = d3.dispatch('change'),
        ignoreChangeEvents = false,
        working,
        mostRecentPath = null,
        mostRecentValue = null,
        om, // the omniscience object used to track property changes
        ubiquity = {};

    /* a JSON strinfiy replacer function for stripping out properties which
    are in the ignore list */
    function replacer(key, value){
        if(key.substr(0,1) == '_' || ignoreList.indexOf(key) != -1){
            return undefined;
        }else{
            return value;
        }
    }

    /* send the current state to the server */
    function sendState(){
        var value = JSON.parse(JSON.stringify(parent[key], replacer));
        socket.emit('room', room, key, value);
    }

    /* for looking up objects in an object tree, a bit like simple 
    xpath for objects */
    function getObjectFromPath(parent, path){
        var current = parent;
        path.forEach(function(prop){
            current = current[prop]
        })
        return current;
    }

    function init(){
        console.log('connecting to ', namespace)
        socket = io.connect(namespace);
        roomHistory = history('room');
        room = roomHistory.get();

        d3.select('#getARoom')
            .on('click', function(){
                room = guid();
                roomHistory.set(room);
                sendState();
            })

        roomHistory.on('change', function(_room){
            room = _room;
            sendState();
        });

        socket.on('connect', function(){
            if (room){
                sendState();
            }
        });

        socket.on('propertyChange', function(path, value){
            console.log('property change', path, value);       
            ignoreChangeEvents = true;
            var prop = path.slice(path.length - 1),
                parentPath = path.slice(0, path.length - 1),
                _parent = getObjectFromPath(parent, parentPath);
            _parent[prop] = value;
            ignoreChangeEvents = false;
            if (path.length == 1){
                dispatch.change();
            }
        })

        socket.on('roomState', function(state){
            console.log('got sent the room state from the server')
            ignoreChangeEvents = true;
            parent[key] = state;
            setupOmniscience()
            ignoreChangeEvents = false;
            dispatch.change();
        })

        return ubiquity;
    }

    function setupOmniscience(){
        om = omniscience(parent, key, ignoreList);
        om.on('propertyChange', function(parent, path, newValue){
            if (ignoreChangeEvents) return;
            if (path[path.length - 1].substr(0,1) == '_') return;
            var value = JSON.parse(JSON.stringify(newValue, replacer));
            socket.emit('propertyChange', path, value)
        })
    }

    /* for attaching event listeners */
    ubiquity.on = function(type, listener){
        dispatch.on(type, listener)
        return ubiquity;
    }

    ubiquity.ignoreChangeEvents = function(_ignoreChangeEvents){
        if (!arguments.length) return ignoreChangeEvents;
        ignoreChangeEvents = _ignoreChangeEvents;
        return ubiquity;
    }

    ubiquity.object = function(_parent, _key){
        if (!arguments.length) return [parent, key];
        parent = _parent;
        key = _key;
        setupOmniscience()
        return ubiquity
    }

    init();

    return ubiquity.object(parent, key);
}