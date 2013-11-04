var d3 = require('d3');

// nothing to do with the seasons of the year, this is just a varation
// on d3.map which sums together values.
module.exports = function(){
    var map = d3.map();

    map.add = function(key, value){
        if (map.has(key)){
            map.set(key, map.get(key)+value)
        }else{
            map.set(key, value)
        }
    }

    map.peak = function(){
        var values = map.values(),
            max = d3.max(values),
            maxPosition = values.indexOf(max);
        return map.entries()[maxPosition]
    }
    
    return map;
}