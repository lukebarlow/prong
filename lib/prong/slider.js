module.exports = function(){

    var dragging = false;
    var width = 40;
    var height = 100;
    var horizontal = false;
    var scale = d3.scale.linear().range(0,height).clamp(true);
    var text;
    var format = d3.format('.2f');
    var circle;
    var dispatch;
    var prefix = '';
    var title = '';
    var value;

    function dragmove(e){
        if (!dragging) return;
        if (horizontal){
            var x = scale(scale.invert(d3.event.x))
            circle.attr('cx', x);
            value = scale.invert(d3.event.x);
            text.text(prefix + format(value));
            text.attr('x', x);
        }else{
            var y = scale(scale.invert(d3.event.y))
            circle.attr('cy', y);
            value = scale.invert(d3.event.y);
            text.text(prefix + format(value));
            text.attr('y', y + 6);
        }
        
        dispatch.change(value);
        d3.event.sourceEvent.stopPropagation();
    }

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
    function slider(g){
        g.each(function() {
            var g = d3.select(this);
            dispatch = d3.dispatch('change','end')

            //g.each(function(item){item.classed('slider')})

            g.attr('class','slider')

            var drag = d3.behavior.drag()
                    .on('dragstart',dragstart)
                    .on('drag',dragmove)
                    .on('dragend',dragend)

            var middle = d3.mean(scale.range())
            value = scale.invert(middle)
            var height = Math.abs(scale.range()[0] - scale.range()[1])

            if (horizontal){
                g.append('rect')
                    .attr('y', 0)
                    .attr('x',scale.range()[0] - width / 2)
                    .attr('height', width)
                    .attr('width', height + width)
                    .attr('rx',width / 2)
                    .attr('ry',width / 2)

                circle = g.append('circle')
                    .attr('cy',width / 2)
                    .attr('cx', middle)
                    .attr('r', width / 2 - 3)
                    .style('cursor','pointer')
                    .attr('fill','white')
                    .call(drag)

                text = g.append('text')
                    .attr('x', middle)
                    .attr('y', width / 2 + 6)
                    .attr('text-anchor','middle')
                    .attr('cursor','pointer')
                    .text(prefix + format(scale.invert(middle)))
                    .call(drag)
            }else{
                g.append('rect')
                    .attr('x', 0)
                    .attr('y',scale.range()[1] - width / 2)
                    .attr('height',height + width)
                    .attr('width', width)
                    .attr('rx',width / 2)
                    .attr('ry',width / 2)

                circle = g.append('circle')
                    .attr('cx',width / 2)
                    .attr('cy', middle)
                    .attr('r', width / 2 - 3)
                    .style('cursor','pointer')
                    .attr('fill','white')
                    .call(drag)

                text = g.append('text')
                    .attr('x',width / 2)
                    .attr('y', middle + 6)
                    .attr('text-anchor','middle')
                    .attr('cursor','pointer')
                    .text(prefix + format(scale.invert(middle)))
                    .call(drag)
            }
        });
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

    slider.height = function(_height){
        if (!arguments.length) return height;
        height = _height;
        if (horizontal){
            scale.range([0,height]);
        }else{
            scale.range([height,0]);
        }
        return slider;
    }

    /* getter/setter for width */
    slider.width = function(_width){
        if (!arguments.length) return width;
        width = _width;
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