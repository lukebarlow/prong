var slider = require('./slider'),
    pot = require('./pot');

module.exports = function(){

    var sequence; // the associated sequence

    var volumeSlider = prong.slider2()
        .domain([0,100])
        .size(100)
        .breadth(40)
        .format(d3.format('f'))
        .key('volume')
        .horizontal(false);

    var pot = prong.pot()
        .domain([-64,+63])
        .radius(20)
        .key('pan')
        .format(d3.format('d'));

    var margin = {top: 40, right: 40, bottom: 40, left: 40},
        width = 1200 - margin.left - margin.right,
        height = 250 - margin.bottom - margin.top;

    function mixer(selection){

        var tracks = sequence.tracks();

        var svg = selection.append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        function redraw(){
            svg.selectAll('g').remove();
            var strips = svg.selectAll('g')
                .data(tracks)
                .enter()
                .append('g')
                .attr('transform', function(d,i){
                    return 'translate(' + i*80 + ',0)';
                })
                .on('mouseover', function(d){
                    d3.select(this).classed('over', true);
                    d.over = true;
                })
                .on('mouseout', function(d){
                    d3.select(this).classed('over', false);
                    d.over = false;
                })
                .each(function(d){
                    var thiz = d3.select(this);
                    d.watch('over', function(){
                        thiz.classed('over', d.over);
                    })
                })

            strips.append('g').call(pot);
            strips.append('g').attr('transform', 'translate(-20,50)').call(volumeSlider);
            strips.append('text')
                .attr('transform', 'translate(0, 190)')
                .attr('text-anchor', 'middle')
                .text(prong.trackName)
        }

        redraw();
    }

    mixer.sequence = function(_sequence){
        if (!arguments.length) return sequence;
        sequence = _sequence;
        return mixer;
    }

    return mixer;
}