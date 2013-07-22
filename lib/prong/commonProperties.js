// a mixin of common properties which can be inherited using d3.rebind
module.exports = function(){
    var x, buffer, width, height;
    var commonProperties = {};

    // getter/setter for x scale
    commonProperties.x = function(_x){
        if (!arguments.length) return x;
        x = _x;
        return commonProperties;
    }

    // this is a getter which calculates the width just by looking
    // at the extremeties of the x range
    commonProperties.width = function(){
        return Math.abs(x.range()[1] - x.range()[0])
    }

    // getter/setter for width
    commonProperties.height = function(_height){
        if (!arguments.length) return height;
        height = _height;
        return commonProperties;
    }

    // getter/setter for width
    commonProperties.sequence = function(_sequence){
        if (!arguments.length) return sequence;
        sequence = _sequence;
        return commonProperties;
    }

    return commonProperties;
}