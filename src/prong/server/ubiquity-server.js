var rooms = {}

function getObjectFromPath(parent, path){
    var current = parent;
    path.forEach(function(prop){
        current = current[prop]
    })
    return current;
}

module.exports = function(sockets){
    sockets.on('connection', function(socket) {
        console.log('socket connected, now waiting for room....')
        socket.on('room', function(room, key, state){
            socket.leave(socket.room || '');
            socket.join(room);
            socket.room = room;
            // if the room already exists, then we send this socket the room state
            if ((room in rooms) && rooms[room][key]){
                socket.emit('roomState', rooms[room][key])
            }else{
                if (!(room in rooms)) rooms[room] = {};
                rooms[room][key] = state;
            }
        })

        socket.on('propertyChange', function(path, value){
            // if the room exists, then update the property
            if (socket.room in rooms){
                var prop = path.slice(path.length - 1),
                    parentPath = path.slice(0, path.length - 1),
                    parent = getObjectFromPath(rooms[socket.room], parentPath);
                parent[prop] = value;
                socket.broadcast.to(socket.room).emit('propertyChange', path, value);
            }
        });
    });
}