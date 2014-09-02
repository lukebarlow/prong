(function(){
    function lyricsTrack(){
        var sequence,
            data,
            intervals,
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
            selection.text('some lyrics');

            var uid = prong.uid();

            data = selection.datum().data,
            intervals = [];

            sequence.on('play.lyrics' + uid, function(){
                var currentTime = sequence.currentTime();
                // find the position of the first lyric to show
                var i = lyricIndexAtTime(data, currentTime);
                selection.text(data[i].text);
                data.slice(i+1).forEach(function(d){
                    console.log('setting an interval for', d)
                    setTimeout(function(){
                        selection.text(d.text);
                    }, 1000 * (d.time - currentTime));
                })
            })

            sequence.on('scrub.lyrics' + uid, function(){
                console.log('scrubbibg');
            })

            sequence.timeline().on('timeselect.lyrics' + uid, function(time){
                var i = lyricIndexAtTime(data, time);
                selection.text(data[i].text);
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

    prong.registerTrackType('lyrics', lyricsTrack);

})();