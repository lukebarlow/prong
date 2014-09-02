var margin = {top: 50, right: 50, bottom: 200, left: 50},
    width = 960 - margin.left - margin.right,
    height = 200 - margin.bottom - margin.top;

var svg, pot;

function drawPots(){

    svg.selectAll('.pot').remove();

    svg.selectAll('.pot')
        .data(values)
        .enter()
        .append('g')
        .attr('class','pot')
        .attr('transform',function(d,i){
            return 'translate(' + i*55 + ',0)';
        })
        .call(pot)
}

function init(){

    pot = prong.pot()
        .domain([-64,+63])
        .radius(20)
        .key('pan')
        .format(d3.format('d'));

    svg = d3.select('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');

    if (values) drawPots();

    var socket = io.connect(),
        roomHistory = prong.history('room'),
        room = roomHistory.get();

    d3.select('#getARoom')
        .on('click', function(){
            room = prong.guid();
            roomHistory.set(room);
            socket.emit('room', room, values);
        })

    roomHistory.on('change', function(room){
        console.log('sending the change')
        socket.emit('room', room, values)
    });

    socket.on('connect', function(){
        if (room){
            console.log('startup sending the change')
            socket.emit('room',room, values);
        }
    });

    socket.on('propertyChange', function(i, key, value){
        values[i][key] = value;
    })

    socket.on('roomState', function(state){
        values = state;
        console.log('got the room state', values);
        drawPots();
    })

    // values.forEach(function(track){
    //     track.id = prong.guid();
    // })

    pot.on('change', function(d, i, key){
        socket.emit('propertyChange', i, key, d[key]);
    })

}