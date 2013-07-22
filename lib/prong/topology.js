// fx = require('./fx')

// // produces a list of local maxima and minima in this file, after smoothing it
// module.exports = function(channel, sampleRate){

//     var thinningFactor = 500,
//         drop = 0.1,
//         time = function(i){return i*thinningFactor/sampleRate};

//     var thinned = fx.thinOut(channel, thinningFactor),
//         maxes = [],
//         mins = [],
//         upturns = [],
//         onsets = [],
//         lastMin = 1,
//         lastMax = 0,
//         lastMaxPosition = null,
//         lastMinPosition = null,
//         ascending = true,
//         lastMaxGradient = 0,
//         lastMaxGradientPosition = null;

//     thinned = thinned.map(Math.abs);

//     var inNote = false,
//         lastUpturnPosition = 0;

//     for (var i=0;i<thinned.length;i++){
//         var value = thinned[i];
//         if (value > lastMax){
//             lastMax = value;
//             lastMaxPosition = i;
//         }
//         if (value < lastMin){
//             lastMin = value;
//             lastMinPosition = i;
//         }
//         if (ascending && value < (lastMax - drop)
//             && (!lastMinPosition || (lastMaxPosition > lastMinPosition))
//             ){
//             ascending = false;
//             maxes.push({value : lastMax, position : time(lastMaxPosition)});
//             lastMaxPosition = null;
//             lastMax = 0;
//         }
//         if (!ascending && value > (lastMin + drop)
//             && (!lastMaxPosition || (lastMinPosition > lastMaxPosition))
//             ){
//             ascending = true;
//             mins.push({value : lastMax, position : time(lastMaxPosition)});
//             lastMinPosition = null;
//             lastMin = 1;
//         }

//         var jump = 10;

//         if (i >= jump){
//             var lookbackSlice = thinned.slice(i-jump, i);
//             var min = d3.min(lookbackSlice);
//             var distanceBack = jump - lookbackSlice.indexOf(min);
//             gradient = (value -  min) / distanceBack;

//             if (gradient > 0.2 && !inNote){
//                 inNote = true;
//                 upturns.push(
//                     {
//                         value : gradient, 
//                         position : (time(i))
//                     });
//                 lastUpturnPosition = i;
//             }

//             if (gradient < -0.01){
//                 inNote = false;
//             }

//             // if (gradient > lastMaxGradient){
//             //     lastMaxGradient = gradient;
//             //     lastMaxGradientPosition = i;
//             // }

//             // if (gradient < -0.01 && lastMaxGradientPosition && lastMaxGradient > 0.05){
//             //     upturns.push({value : lastMaxGradient, position : time(lastMaxGradientPosition)})
//             //     lastMaxGradient = 0;
//             //     lastMaxGradientPosition = null;
//             // }

//         }

        

//     }

//     return {maxes : maxes, mins : mins, upturns : upturns}

// }