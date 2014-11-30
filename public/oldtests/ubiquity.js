function ubiquity(parent, key){

    var socket, 
        roomHistory, 
        room, 
        dispatch = d3.dispatch('change'),
        ignoreChangeEvents = false,
        om;

    function sendState(){
        socket.emit('room', room, key, parent[key])
    }

    function getObjectFromPath(parent, path){
        var current = parent;
        path.forEach(function(prop){
            current = current[prop]
        })
        return current;
    }

    var ubiquity = {};

    ubiquity.init = function(){
        socket = io.connect();
        roomHistory = prong.history('room');
        room = roomHistory.get();

        d3.select('#getARoom')
            .on('click', function(){
                room = prong.guid();
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
            ignoreChangeEvents = true;
            var prop = path.slice(path.length - 1),
                parentPath = path.slice(0, path.length - 1),
                _parent = getObjectFromPath(parent, parentPath);
            _parent[prop] = value;
            ignoreChangeEvents = false;
            dispatch.change()
        })

        socket.on('roomState', function(state){
            ignoreChangeEvents = true;
            parent[key] = state;
            setupOmniscience()
            ignoreChangeEvents = false;
            dispatch.change();
        })

        return ubiquity;
    }

    function setupOmniscience(){
        om = omniscience(parent, key);
        om.on('propertyChange', function(parent, path, newValue){
            if (ignoreChangeEvents) return;
            socket.emit('propertyChange', path, newValue)
        })
    }

    /* for attaching event listeners */
    ubiquity.on = function(type, listener){
        dispatch.on(type, listener)
        return ubiquity;
    }

    ubiquity.object = function(_parent, _key){
        if (!arguments.length) return [parent, key];
        parent = _parent;
        key = _key;
        setupOmniscience()
        return ubiquity
    }

    ubiquity.init().object(parent, key);

    return ubiquity;
}