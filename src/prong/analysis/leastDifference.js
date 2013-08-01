

// mean sqaure of the difference between two arrays assumed to be the same
// length. If b is longer than a, then the extra elements in b will be ignored.
// If a is longer than b, then it will throw an error
function meanDiff(a, b){
    return d3.mean(a, function(d,i){
        return (d-b[i])*(d-b[i]); // square of the difference
        //return (d*b[i])*(d*b[i])
    })
}


// calculate the offset between 2 arrays which gives the smallest average
// difference between values
module.exports = function(a, b, overlapRatio){
    var minOverlap = parseInt(d3.min([a.length, b.length]) * overlapRatio);

    // var diffs = d3.map(),
    //     i = 0,
    //     vals = []

    var min = Infinity,
        minOffset = null,
        totalOffset = 0,
        count = 0;

    function checkValue(value, offset){
        if (value < min){
            min = value;
            minOffset = offset;
        }
        totalOffset += value;
        count++;
    }

    // the stage where b is to the left of a
    var offsets = d3.range(minOverlap-b.length,-1)
    offsets.forEach(function(offset){

        var val = meanDiff(
            a.slice(0, b.length+offset),
            b.slice(-offset)
        )

        checkValue(val, offset);

        // vals.push(val)

        // diffs.set(offset, val)
    })

    // where they start at the same point

    var val = meanDiff(
        a.slice(0, b.length),
        b
    )

    checkValue(val, 0);

    // vals.push(val)

    // diffs.set(0, val)

    offsets = d3.range(1,a.length-minOverlap);
    offsets.forEach(function(offset){
        var val = meanDiff(
            a.slice(offset, b.length+offset),
            b
        )

        checkValue(val, offset);

        // vals.push(val)
        // diffs.set(offset, val)
    })


    var confidence = totalOffset / count / min;

    return {offset : minOffset, confidence : confidence}
}