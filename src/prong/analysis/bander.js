
// will break a magnitude spectrum into bands, and return an array of
// the max value in each band
module.exports = function(n, sampleRate, bands){

    var lookup;

    // if bands are plain numbers, then turn them into objects with
    // low and high properties
    bands = bands.map(function(band,i){
        if (typeof(band) == 'number'){
            band = {
                high : band,
                low : i>0 ? bands[i-1] : 0
            }
        }
        return band;
    })

    // compiles a lookup dictionary from magnitude position
    // to band.
    function compileLookup(){
        lookup = new Uint8Array(n)
        var bandIndex = 0,
            band = bands[bandIndex],
            previousBand = null;

        for (var i=0;i<n;i++){
            var frequency = i * sampleRate / n;
            if (band && frequency > band.high){
                bandIndex++;
                band = bands[bandIndex];

            }
            lookup[i] = band && frequency >= band.low && frequency < band.high ? bandIndex : null;
        }
    }

    compileLookup();

    var bander = function(magnitudes){
        var result = bands.map(function(){return []})
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