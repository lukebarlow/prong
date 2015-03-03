d3 = require('../d3-prong-min')

module.exports = function(){
    var sequence,
        dispatch = d3.dispatch('load');

    // returns the index in the data array for the lyric which
    // should be shown at the specified time
    function lyricIndexAtTime(data, time){
        var i=0;
        for (;i<data.length;i++){
            if (data[i].time > time) break;
        }
        if (i > 0)i--;
        return i;
    }

    function lyricsTrack(selection, options){

        selection.append('span').text(prong.trackName).attr('class','trackName');   
        
        var display = selection.append('div')     
        //selection.text(' ');
        display.classed('lyrics', true)

        var uid = prong.uid(),
            data = selection.datum().data,
            timeouts = [];

        sequence.on('play.lyrics' + uid, function(){
            var currentTime = sequence.currentTime();
            // find the position of the first lyric to show
            var i = lyricIndexAtTime(data, currentTime);
            display.text(data[i].text);
            data.slice(i+1).forEach(function(d){
                timeouts.push(setTimeout(function(){
                    display.text(d.text);
                }, 1000 * (d.time - currentTime)));
            })
        })

        sequence.on('stop.lyrics' + uid, function(){
            timeouts.map(clearTimeout);
        })

        sequence.on('scrub.lyrics' + uid, function(){
            console.log('scrubbibg');
        })

        sequence.timeline().on('timeselect.lyrics' + uid, function(time){
            var i = lyricIndexAtTime(data, time);
            display.text(data[i].text);
        })
    }

    lyricsTrack.sequence = function(_sequence){
        if (!arguments.length) return sequence;
        sequence = _sequence;
        return lyricsTrack;
    }

    lyricsTrack.on = function(type, listener){
        dispatch.on(type, listener);
        return lyricsTrack;
    }

    return lyricsTrack;
}
