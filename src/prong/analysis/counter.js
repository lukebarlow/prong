var d3 = require('d3');

// a special kind of d3.map which just counts the occurences of a key
module.exports = function(){
    var map = d3.map();

    map.add = function(key){
        if (map.has(key)){
            map.set(key, map.get(key)+1)
        }else{
            map.set(key, 1)
        }
    }

    map.most = function(){
        var values = map.values(),
            max = d3.max(values),
            maxPosition = values.indexOf(max);
        return map.entries()[maxPosition]
    }
    return map;
}