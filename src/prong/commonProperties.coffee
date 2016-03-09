# a mixin of common properties which can be inherited using d3.rebind
module.exports = ->
    x = null
    buffer = null
    width = null
    height = null
    timeline = null
    sequence = null
    historyKey = null
    commonProperties = {}

    # getter/setter for x scale
    commonProperties.x = (_x) ->
        if (!arguments.length) then return x
        x = _x
        return commonProperties
    

    # this is a getter which calculates the width just by looking
    # at the extremeties of the x range
    commonProperties.width = ->
        if timeline
            _x = timeline.x()
        else
            _x = x
        return Math.abs(_x.range()[1] - _x.range()[0])
    

    # getter/setter for width
    commonProperties.height = (_height) ->
        if (!arguments.length) then return height
        height = _height
        return commonProperties
    

    # getter/setter for width
    commonProperties.sequence = (_sequence) ->
        if (!arguments.length) then return sequence
        sequence = _sequence
        return commonProperties
    

    commonProperties.timeline = (_timeline) ->
        if (!arguments.length) then return timeline
        timeline = _timeline
        return commonProperties


    commonProperties.historyKey = (_historyKey) ->
        if (!arguments.length) then return historyKey
        historyKey = _historyKey
        return commonProperties
    

    return commonProperties
