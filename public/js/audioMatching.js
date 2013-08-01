// // looks for the best match of time differences between offsets, and
// // so sets the start time for each track. Returns true if it managed to
// // match all tracks, or false if it didn't
// function calculateBestStartTimes(tracks){
//     // reset all the start times
//     tracks.forEach(function(track){
//         track.previousStartTime = track.startTime || 0;
//         track.startTime = 0}
//     );
//     var a = tracks[0].onsetDiffs;
//     for (var i=1;i<tracks.length;i++){
//         var b = tracks[i].onsetDiffs
//         var timeDiffs = d3.map();
//         a.forEach(function(key,value){
//             if (b.has(key)){
//                 var diff = d3.round(value - b.get(key),3)
//                 if (timeDiffs.has(diff)){
//                     timeDiffs.set(diff, timeDiffs.get(diff) + 1);
//                 }else{
//                     timeDiffs.set(diff,1);
//                 }
//             }
//         })

//         var values = timeDiffs.values()
//         var maxMatches = d3.max(values)
//         if (maxMatches >= 5){
//             var bestDiff = timeDiffs.keys()[values.indexOf(maxMatches)]
//             trackToMove = i
//             tracks[trackToMove].startTime = parseFloat(bestDiff);

//             // these next few lines only needed if you want to display the
//             // matched times. They add an extra property to the first track
//             // which is a list of matched times
//             var matchingTimes = [];
//             var round3 = function(x){return d3.round(x,3)}

//             tracks[0].roundedOnsetTimes = tracks[0].onsetTimes.map(round3);
//             tracks[1].roundedOnsetTimes = tracks[1].onsetTimes.map(function(x){
//                 return round3(x) - tracks[0].startTime + tracks[1].startTime;
//             });

//             tracks[0].roundedOnsetTimes.forEach(function(time){
//                 tracks[1].roundedOnsetTimes.forEach(function(track1Time){
//                     if(Math.abs(time - track1Time) < 0.01){
//                         matchingTimes.push(time);
//                     }
//                 })
//             })
//             tracks[0].matchingTimes = matchingTimes;
//             tracks[1].matchingTimes = [];
//         }
//     }

//     // finally, we move all start times forward so the earliest track
//     // starts at zero
//     var minStartTime = d3.min(tracks, function(track){return track.startTime})
//     tracks.forEach(function(track){track.startTime -= minStartTime})

//     var maxStartTime = d3.max(tracks, function(track){return track.startTime});
//     return maxStartTime;
// }

function moveToStartTimes(){
    d3.selectAll('.track').select('.audio')
        .transition()
        .duration(1000)
        .style('padding-left', function(d,i){
            return (x(d.startTime) - x(d.previousStartTime)) + 'px'
        });

    // d3.selectAll('.track').select('.filmstrip')
    //     .transition()
    //     .duration(1000)
    //     .style('padding-left', function(d,i){
    //         return (x(d.startTime) - x(d.previousStartTime)) + 'px'
    //     });

    sequence.timeline().on('change.resetPadding', function(){
        d3.selectAll('.track').select('.audio').style('padding-left', '0px');
        //d3.selectAll('.track').select('.filmstrip').style('padding-left', '0px');
        sequence.timeline().on('change.resetPadding', null);
    })
}