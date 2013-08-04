var FFT = require('fft'),
    Bander = require('./bander'),
    fx = require('./fx'),
    leastDifference = require('./leastDifference'),
    summer = require('./summer');

module.exports = {
    calculateBestStartTimes : calculateBestStartTimes,
    diffs : diffs,
    noteDiffs : noteDiffs,
    pitchAtTime : pitchAtTime,
    diffMatches : diffMatches,
    bands : bands,
    matchLeastDiff : matchLeastDiff,
}

function round3(x){return d3.round(x,3)};

// from http://en.wikipedia.org/wiki/Pitch_(music)#Pitch_and_frequency
function pitchFromFrequency(frequency){
    var f = frequency / 440;
    return 69 + 12 * Math.log(f) / Math.LN2;
}

function fftAtTime(channel, sampleRate, time){
    var n = 1024,
        frequencyHeight = n/4,
        fft = new FFT.complex(n, false),
        input = channel.subarray(time*sampleRate, time*sampleRate + n),
        output = new Float32Array(n * 2);

    fft.simple(output, input, 'real');

    return output;
}

function fftMagnitudesAtTime(channel, sampleRate, time){
    var spectrum = fftAtTime(channel, sampleRate, time),
        magnitudes = new Float32Array(spectrum.length / 2),
        length = spectrum.length / 2;

    for (var i=0;i<length;i++){
        magnitudes[i] = Math.sqrt(spectrum[i*2]*spectrum[i*2]+spectrum[i*2+1]*spectrum[i*2+1]);
    }

    return magnitudes;
}

function frequencyAtTime(channel, sampleRate, time){
    var n = 1024,
        spectrum = fftAtTime(channel, sampleRate, time),
        maxPosition, 
        max = 0;

    for (var i=0;i<spectrum.length/2;i++){
        var value = Math.sqrt(spectrum[i*2]*spectrum[i*2]+spectrum[i*2+1]*spectrum[i*2+1]);
        if (value > max){
            max = value;
            maxPosition = i;
        }
    }

    var frequency = maxPosition * sampleRate / n;

    return frequency;
}


function pitchAtTime(channel, sampleRate, time){
    return pitchFromFrequency(frequencyAtTime(channel, sampleRate, time));
}

// the first argument should be an array of tracks. Each track must have a
// property 'onsetTimes' which is a list of times. This algorithm calculates the
// gaps between these times, and compares these gaps across tracks. If it finds
// the same gaps between times in both tracks, then it will set the 'startTime'
// property of the tracks so that they line up
//
// the optional 'withMatchedTimes' flag can be used to get an additional
// property on the tracks which is a list of the times which matched
//
// each track is matched against the first track only
function calculateBestStartTimes(tracks, withMatchedTimes){
    tracks.forEach(function(track){
        track.previousStartTime = track.startTime || 0;
        track.startTime = 0}
    );

    var a = tracks[0].onsetDiffs;
    for (var i=1;i<tracks.length;i++){
        var b = tracks[i].onsetDiffs
        var timeDiffs = d3.map();
        a.forEach(function(key,endTimesA){
            // look for a matching diff
            if (b.has(key)){

                // now we have a match, we should go through all the
                // permutations of endTimes from a and b
                var endTimesB = b.get(key);
                endTimesA.forEach(function(timeA){
                    endTimesB.forEach(function(timeB){
                        var diff = d3.round((timeA - timeB),3)
                        if (timeDiffs.has(diff)){
                            timeDiffs.set(diff, timeDiffs.get(diff) + 1);
                        }else{
                            timeDiffs.set(diff,1);
                        }
                    })
                })
            }
        });

        // filter the time diffs down to the ones
        var topTimeDiffs = d3.map();

        timeDiffs.forEach(function(key, value){
            if (value > 5){
                topTimeDiffs.set(key, value)
            }
        })

        //console.log(topTimeDiffs);

        // temp, from https://github.com/mbostock/d3/pull/1073
        var calcVariance = function(x) {
          var n = x.length;
          if (n < 1) return NaN;
          if (n === 1) return 0;
          var mean = d3.mean(x),
              i = -1,
              s = 0;
          while (++i < n) {
            var v = x[i] - mean;
            s += v * v;
          }
          return s / (n - 1);
        };

        var values = timeDiffs.values()
        var maxMatches = d3.max(values)
        var variance = calcVariance(values);
        var mean = d3.mean(values);
        var confidence = maxMatches / mean;
        console.log('confidence:' + confidence);
        console.log('max matches:' + maxMatches);
        console.log('variance:' + variance)
        console.log('confidence2:' + (maxMatches - mean) / variance);

        if (maxMatches >= 5){
            var bestDiff = timeDiffs.keys()[values.indexOf(maxMatches)]
            trackToMove = i
            tracks[trackToMove].startTime = parseFloat(bestDiff);

            // these next few lines only needed if you want to display the
            // matched times. They add an extra property to the first track
            // which is a list of matched times
            if (withMatchedTimes){
                tracks[0].matchingTimes = [];
                var matchingTimes = [];

                tracks[0].roundedOnsetTimes = tracks[0].onsetTimes.map(round3);
                tracks[i].roundedOnsetTimes = tracks[i].onsetTimes.map(function(x){
                    return round3(x) - tracks[0].startTime + tracks[i].startTime;
                });

                tracks[0].roundedOnsetTimes.forEach(function(time1){
                    tracks[i].roundedOnsetTimes.forEach(function(time2){
                        if(Math.abs(time1 - time2) < 0.01){
                            matchingTimes.push(time2);
                        }
                    })
                });
                tracks[i].matchingTimes = matchingTimes;
            } 
        }
    }

    // finally, we move all start times forward so the earliest track
    // starts at zero
    var minStartTime = d3.min(tracks, function(track){return track.startTime})
    tracks.forEach(function(track){track.startTime -= minStartTime})
    var maxStartTime = d3.max(tracks, function(track){return track.startTime});

    return maxStartTime;
}

/*
The first argument, 'values', is  a list of values which are expected to
be already sorted in ascending order. This method returns a d3.map where the 
keys are the differences between these values and the map values are the values 
where these diffs end. The 'lookbackLimit' determines how many of the list of
values it will jump across in finding diffs. For example, if values are 
[a,b,c,d] and lookback limit is 2, then the result is

{
    b-a : b,
    c-b : c,
    d-c : d,
    c-a : c,
    d-b : d
}

Note that the diff d-a is not included, since this is a jump of 3.
*/
function diffs(times, decimalPlaces, lookbackLimit){

    lookbackLimit = lookbackLimit || 200;
    decimalPlaces = decimalPlaces || 3;
    
    var round = function (x){return d3.round(x,decimalPlaces)},
        diffMap = d3.map();
       // doubleDiffs = d3.map();

    for (var i=1;i<times.length;i++){
        var limit = Math.min(i,lookbackLimit);
        for (j=1;j<=limit;j++){
            var diff = round(times[i]-times[i-j]),
                endTime = round(times[i]);

            if (diffMap.has(diff)){
                diffMap.get(diff).push(endTime);
            }else{
                diffMap.set(diff, [endTime]);
            }
        }
    }

    return diffMap;
}


function noteDiffs(notes, decimalPlaces, lookbackLimit){

    lookbackLimit = lookbackLimit || 200;
    decimalPlaces = decimalPlaces || 3;
    
    var round = function (x){return d3.round(x,decimalPlaces)},
        diffMap = d3.map();
       // doubleDiffs = d3.map();

    for (var i=1;i<notes.length;i++){
        var limit = Math.min(i,lookbackLimit);
        for (j=1;j<=limit;j++){
            var timeDiff = round(notes[i][0]-notes[i-j][0]),
                endTime = round(notes[i][0]),
                key = d3.round(timeDiff,2)// + ':' //+ d3.round(notes[i][1],0)// + '-' + d3.round(notes[j][1],0);

            if (diffMap.has(key)){
                diffMap.get(key).push(endTime);
            }else{
                diffMap.set(key, [endTime]);
            }
        }
    }

    return diffMap;
}

// looks for common diffs between two sets of diffs, and relates these
// to the offset between the two tracks. It returns the number of matches
// for each possible offset. By looking
function diffMatches(diffsA, diffsB){
    var possibleOffsets = d3.map()
    diffsA.forEach(function(key,endTimesA){
        // look for a matching diff
        if (diffsB.has(key)){
            // now we have a match, we should go through all the
            // permutations of endTimes from a and b
            var endTimesB = diffsB.get(key);
            endTimesA.forEach(function(timeA){
                endTimesB.forEach(function(timeB){
                    var diff = d3.round((timeA - timeB),3)
                    if (possibleOffsets.has(diff)){
                        possibleOffsets.set(diff, possibleOffsets.get(diff) + 1);
                    }else{
                        possibleOffsets.set(diff,1);
                    }
                })
            })
        }
    });
    return possibleOffsets;
}


// does a fourier analysis every 'interval' along the channel, and at each
// point picks out the dominant frequency
function simpleFingerprint(channel, sampleRate, interval){
    var duration = channel.length / sampleRate;
    var frequencies = [];
    for (var i=0;i<duration;i+=interval){
        frequencies.push(d3.round(frequencyAtTime(channel, sampleRate, i)))
    }

    var prints = [];
    for (var i=0;i<frequencies.length-3;i++){
        var f1 = frequencies[i], f2 = frequencies[i+1], f3 = frequencies[i+2]
        if (f1 == f2 && f2 == f3){
            console.log('got 3 identical')
        }
        prints.push(frequencies[i]+':'+frequencies[i+1]+':'+frequencies[i+2])
    }

    return prints;
}

function bands(channel, sampleRate, interval, bands){
    // in each frequency band, find the onsets
    var duration = channel.length / sampleRate,
        frequencies = [],
        result = null;

    var bander = Bander(1024, sampleRate, bands);

    for (var i=0;i<duration;i+=interval){
        var r = bander(fftMagnitudesAtTime(channel, sampleRate, i))
        if (!result){
            result = r.map(function(){return []});
        }
        r.forEach(function(strength, index){
            result[index].push(strength)
        });
    }

    // lastly, normalise each band
    result.forEach(function(strengths, i){
        var multiplier = 1 / d3.max(strengths);
        for(var i=0;i<strengths.length;i++){
            strengths[i] *= multiplier;
        }
    })

    return result;
}

// uses the least difference method to find a match between tracks
function matchLeastDiff(tracks, interval, frequencyBands){

    var contourSampleRate = 1/interval;

    console.log('the band bit')
    var t1 = new Date();

    // first get the bands for each track
    tracks.forEach(function(track, position){
        var buffer = track.buffer,
            channel = track.channel;

        track.bands = bands(channel, buffer.sampleRate,
                interval, frequencyBands)

        track.bands.forEach(function(band){
            fx.localNormalise(band,1.1);
        })
    });

    console.log('the diff bit')
    var t2 = new Date();

    tracks.forEach(function(track){
        track.previousStartTime = track.startTime || 0;
    })

    tracks[0].startTime = 0;

    var confidenceOfAnswers,
        mostConfident;

    for (var i=1;i<tracks.length;i++){
        confidenceOfAnswers = summer();
        // match each track to the first track
        frequencyBands.forEach(function(frequency,j){
            // assumes two tracks
            var ret = leastDifference(tracks[0].bands[j], tracks[i].bands[j], 0.5),
                timeOfMax = d3.round(ret.offset / contourSampleRate, 2);
            confidenceOfAnswers.add(timeOfMax, ret.confidence);
        })

        mostConfident = confidenceOfAnswers.most();
        tracks[i].startTime = parseFloat(mostConfident.key);
    }

    var t3 = new Date(),
        bandTime = t2 - t1,
        diffTime = t3 - t2,
        ratio = d3.round(diffTime / bandTime, 2);

    console.log('band time : ' + bandTime);
    console.log('diff time : ' + diffTime);
    console.log('ratio : ' + ratio);

    // finally, we move all start times forward so the earliest track
    // starts at zero
    var minStartTime = d3.min(tracks, function(track){return track.startTime})
    tracks.forEach(function(track){track.startTime -= minStartTime})

    return mostConfident.key;
}

