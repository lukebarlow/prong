/* A rotating circular tweakable knob, like a pan or fx control */

module.exports = function(){

    var dragging = false,
        radius = 20,
        angle = Math.PI * 0.65,
        scale = d3.scale.linear().range([-angle, angle]).clamp(true),
        format = d3.format('f'),
        dispatch = d3.dispatch('change','end'),
        prefix = '',
        title = '',
        key;

    function dragstart(e){
        dragging = true;
        d3.event.sourceEvent.stopPropagation();
    }

    function dragend(e){
        dragging = false;
        //dispatch.end(value);
        d3.event.sourceEvent.stopPropagation();
    }

    /* the main function */
    function pot(selection){

        selection.attr('class','pot')

        var drag = d3.behavior.drag()
            .on('dragstart',dragstart)
            .on('drag',dragmove)
            .on('dragend',dragend);

        var backgroundArc = d3.svg.arc()
            .outerRadius(radius + 12)
            .innerRadius(radius)
            .startAngle(-angle)
            .endAngle(angle);

        var arc = d3.svg.arc()
            .outerRadius(radius + 12)
            .innerRadius(radius)
            .startAngle(function(d){
                var value = d[key];
                return scale(value < 0 ? value : 0);
            })
            .endAngle(function(d){
                var value = d[key];
                return scale(value > 0 ? value : 0);
            })

        selection.append('circle')
            .attr('r', radius)
            .call(setupEvents)

        selection.append('path')
            .attr('class', 'background')
            .attr('d', backgroundArc)

        selection.append('path')
            .attr('class', 'arc pan')
            .attr('d', arc)

        selection.append('text')
            .attr('text-anchor','middle')
            .attr('transform','translate(0,'+radius/4+')')
            .text(function(d){return d[key]})
            .call(setupEvents)

        // use the Object.watch feature to listen for changes to the datum
        // and redraw
        selection.each(function(d){
            d.watch(key, function(){
                redraw(d)
            })
        })

        function setupEvents(selection){
            selection.call(drag)
                .on('dblclick', function(d){
                    d[key] = 0;
                    redraw();
                })
        }

        function dragmove(d, i){
            d[key] -= d3.event.dy;
            var min = scale.domain()[0],
                max = scale.domain()[1];
            if (d[key] > max) d[key] = max;
            if (d[key] < min) d[key] = min;
            redraw();
            dispatch.change(d, i, key)
        }

        function redraw(d){
            selection.selectAll('.arc')
                .attr('d', arc)
            selection.selectAll('text')
                .text(function(d){return d[key]})
        }

    }

    /* getter/setter for the domain of the pot. i.e. the range of
       values it slides over. This should be be a two element array.

        e.g. [0,100] makes a pot which slides between values 0 and 100
        */
    pot.domain = function(_domain){
        if (!arguments.length) return scale.domain();
        scale.domain(_domain)
        return pot;
    }

    /* getter/setter for width */
    pot.radius = function(_radius){
        if (!arguments.length) return radius;
        radius = _radius;
        return pot;
    }

    /* getter/setter for format */
    pot.format = function(_format){
        if (!arguments.length) return format;
        format = _format;
        return pot;
    }

    /* for attaching event listeners */
    pot.on = function(type, listener){
        dispatch.on(type, listener)
        return pot;
    }

    pot.key = function(_key){
        if (!arguments.length) return key;
        key = _key;
        return pot;
    }

    return pot;
}