module.exports = function(){

    var dragging = false,
        breadth = 40,
        size = 100,
        horizontal = false,
        scale = d3.scale.linear().range(0,size).clamp(true),
        format = d3.format('.2f'),
        dispatch = d3.dispatch('change','end'),
        prefix = '',
        title = '',
        value,
        key,
        padding = 1;

    function dragstart(e){
        dragging = true;
        d3.event.sourceEvent.stopPropagation();
    }

    function dragend(e){
        dragging = false;
        dispatch.end(value);
        d3.event.sourceEvent.stopPropagation();
    }

    /* the main function */
    function slider(selection){

        var g = selection;

        g.attr('class','slider');

        var drag = d3.behavior.drag()
                .on('dragstart',dragstart)
                .on('drag',dragmove)
                .on('dragend',dragend);
        var circle, text, background;

        var height = Math.abs(scale.range()[0] - scale.range()[1]);

        function position(d){ return scale(d[key])};
        function text(d){return prefix + format(d[key])};

        if (horizontal){
            g.append('rect')
                .attr('y', 0)
                .attr('x',scale.range()[0] - breadth / 2)
                .attr('height', breadth)
                .attr('width', height + breadth)
                .attr('rx',breadth / 2)
                .attr('ry',breadth / 2)

            circle = g.append('circle')
                .attr('cy',breadth / 2)
                .attr('cx', position)
                .attr('r', breadth / 2 - 3)
                .style('cursor','pointer')
                .attr('fill','white')
                .call(drag)

            text = g.append('text')
                .attr('x', position)
                .attr('y', breadth / 2 + 6)
                .attr('text-anchor','middle')
                .attr('cursor','pointer')
                .text(text)
                .call(drag)
        }else{
            g.append('rect')
                .attr('x', 0)
                .attr('y',scale.range()[1] - breadth / 2)
                .attr('height',height + breadth)
                .attr('width', breadth)
                .attr('rx',breadth / 2)
                .attr('ry',breadth / 2)

            background = g.append('rect')
                .attr('class','background')
                .attr('x', padding)
                .attr('y', function(d){return position(d) - breadth/2 + padding})
                .attr('height',function(d){return height - position(d) + breadth - padding*2})
                .attr('width', breadth - padding*2)
                .attr('rx',breadth / 2)
                .attr('ry',breadth / 2)

            circle = g.append('circle')
                .attr('cx',breadth / 2)
                .attr('cy', position)
                .attr('r', breadth / 2 - 2)
                .style('cursor','pointer')
                .attr('fill','white')
                .call(drag)

            text = g.append('text')
                .attr('x',breadth / 2)
                .attr('y', function(d){return position(d) + 6})
                .attr('text-anchor','middle')
                .attr('cursor','pointer')
                .text(text)
                .call(drag)
        }

        selection.each(function(d){
            d.watch(key, function(){
                redraw(d)
            })
        })

        function dragmove(d, i){
            if (!dragging) return;
            d[key] = scale.invert(horizontal ? d3.event.x : d3.event.y);            
            text.text(prefix + format(d[key]));
            redraw();
            dispatch.change(d, i, key);
            d3.event.sourceEvent.stopPropagation();
        }

        function redraw(d){
            if (horizontal){

            }else{
                circle.attr('cy', function(d){return scale(d[key])})
                text.attr('y', function(d){ return scale(d[key]) + 6 })
                    .text(function(d){ return prefix + format(d[key]) })
                background
                    .attr('y', function(d){return position(d) - breadth/2 + padding})
                    .attr('height',function(d){return height - position(d) + breadth - padding*2})
            }
        }
    }

    /* getter/setter for the domain of the slider. i.e. the range of
       values it slides over. This should be be a two element array.

        e.g. [0,100] makes a slider which slides between values 0 and 100
        */
    slider.domain = function(_domain){
        if (!arguments.length) return scale.domain();
        scale.domain(_domain)
        return slider;
    }

    /* getter/setter for the length of the slider */
    slider.size = function(_size){
        if (!arguments.length) return size;
        size = _size;
        if (horizontal){
            scale.range([0,size]);
        }else{
            scale.range([size,0]);
        }
        return slider;
    }

    /* getter/setter for breadth */
    slider.breadth = function(_breadth){
        if (!arguments.length) return breadth;
        breadth = _breadth;
        return slider;
    }

    /* getter/setter for format */
    slider.format = function(_format){
        if (!arguments.length) return format;
        format = _format;
        return slider;
    }

    /* getter/setter for prefix */
    slider.prefix = function(_prefix){
        if (!arguments.length) return prefix;
        prefix = _prefix;
        return slider;
    }

    /* getter/setter for horizontal setting */
    slider.horizontal = function(_horizontal){
        if (!arguments.length) return horizontal;
        if (_horizontal && !horizontal){
            // flip the range
            var range = scale.range()
            scale.range([range[1],range[0]])
        }
        horizontal = _horizontal;

        return slider;
    }

    /* for attaching event listeners */
    slider.on = function(type, listener){
        dispatch.on(type, listener)
        return slider;
    }

    slider.key = function(_key){
        if (!arguments.length) return key;
        key = _key;
        return slider;
    }

    /* getter/setter for prefix */
    slider.title = function(_title){
        if (!arguments.length) return title;
        title = _title;
        return slider;
    }

    slider.value = function(_value){
        if (!arguments.length) return value;
        value = _value;
        circle.attr(horizontal ? 'cx' : 'cy',scale(value))
        text.attr(horizontal ? 'x' : 'y' ,scale(value) + (horizontal ? 0 : 6))
            .text(prefix + format(value))
        return slider;
    }

    return slider;
}