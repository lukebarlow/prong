

// mean sqaure of the difference between two arrays assumed to be the same
// length. If b is longer than a, then the extra elements in b will be ignored.
// If a is longer than b, then it will throw an error
function meanDiff(a, b){
    return d3.mean(a, function(d,i){
        return (d-b[i])*(d-b[i]); // square of the difference
        //return (d*b[i])*(d*b[i])
    })
}

function diffsByOffset(a, b, minOverlap){
    // we imagine a as staying still, and b being moved by the offset
    //var diffs = d3.map();

    //var diffs2 = new Uint32Array(a.length + b.length - 1),
    var i = 0,
        minValue = Infinity,
        minPosition = null,
        totalValue = 0;

    function checkValue(value){
        if (value < minValue){
            minValue = value;
            minPosition = i;
        }
        i++;
        totalValue += value;
    }

    // the stage where b is to the left of a
    var offsets = d3.range(minOverlap-b.length,-1)
    offsets.forEach(function(offset){

        var val = meanDiff(
            a.slice(0, b.length+offset),
            b.slice(-offset)
        )

        checkValue(val);
        // diffs.set(offset, val);
        // diffs2[i++] = val;

    })

    // where they start at the same point
    

    var val = meanDiff(
        a.slice(0, b.length),
        b
    )

    checkValue(val);

    // diffs.set(0, val);
    // diffs2[i++] = val;

    offsets = d3.range(1,a.length-minOverlap);
    offsets.forEach(function(offset){

        var val = meanDiff(
            a.slice(offset, b.length+offset),
            b
        )

        checkValue(val);

        // diffs.set(offset, val)
        // diffs2[i++] = val;
    })

    return {
        offset : minPosition + 1 - b.length,
        confidence : totalValue / i / minValue
    }

    //return diffs2;
    //return diffs;
}

// calculate the offset between 2 arrays which gives the smallest average
// difference between values
module.exports = function(a, b, overlapRatio){
    var minOverlap = parseInt(d3.min([a.length, b.length]) * overlapRatio);

    return diffsByOffset(a,b, minOverlap);
        // values = diffs.values(),
        // min = d3.min(values),
        // minPosition = values.indexOf(min),
        // minOffset = diffs.keys()[minPosition],
        // confidence = d3.mean(values) / min;

    //var min = Infinity;
    //for (var i=0;i<)

    //     min = d3.min(diffs),
    //     minPosition = diffs.indexOf(min),
    //     minOffset = minPosition + 1 - b.length,
    //     confidence = d3.mean(diffs) / min;

    // return {offset : minOffset, confidence : confidence}
}