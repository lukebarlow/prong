
// it assigns each position in the fft result to a note in a dodecaphonic scale.
// i.e. C,C#,D,Eb,E...Bb,B
module.exports = function(n, sampleRate){

    var lookup;

    function pitchFromFrequency(frequency){
        var f = frequency / 440;
        return 69 + 12 * Math.log(f) / Math.LN2;
    }

    // compiles a lookup dictionary from magnitude position
    // to band.
    function compileLookup(){
        lookup = new Uint8Array(n)
        for (var i=0;i<n;i++){
            var frequency = i * sampleRate / n;
            lookup[i] = pitchFromFrequency(frequency) % 12;
        }
    }

    compileLookup();

    var bander = function(magnitudes){
        var result = d3.range(12).map(function(){return []})
        for (var i=0;i<magnitudes.length;i++){
            if (lookup[i] != null){
                result[lookup[i]].push(magnitudes[i])
            }
        }
        return result.map(function(values){
            return d3.max(values) || 0;
        });
    }

    return bander;
}