var pool = pool || {}

pool.videoPlayer = function(){

    var tracks, editList, videos, timeouts, element;

    // used to determine if a track is the same track as another
    function trackId(track){
        switch(track.type){
            case 'audio' :
            case 'video' :
                return track.src;
            break;
            case 'videoPreparation' :
                return track.sourceId;
            break;
        }
    }

    // function videoPlayer(selection){
    //     // filter down to video tracks
    //     var videoTracks = tracks.filter(function(track){
    //         return track.type == 'video'
    //     });

    //     videos = selection.selectAll('video')
    //         .data(videoTracks, trackId)
    //         .enter()
    //         .append('video')
    //         .attr('width',500)
    //         .attr('height',100);

    //     videos.append('source')
    //         .attr('type','video/ogg')
    //         .attr('src', function(d){return d.src});
    // }
    videoPlayer = {};


    // getter/setter for tracks
    videoPlayer.tracks = function(_tracks){
        if (!arguments.length) return tracks;
        tracks = _tracks;
        tracks.forEach(function(track){
            if (!('startTime' in track)){
                track.startTime = 0;
            }
        })
        return videoPlayer;
    }

    // getter setter for the edit list
    videoPlayer.editList = function(_editList){
        if (!arguments.length) return editList;
        editList = _editList;
        return videoPlayer;
    }

    videoPlayer.showVideo = function(index, videos){
        // videos = videos || element.selectAll('video');
        // videos.each(function(d,i){
        //     this.style.visibility = (index == i) ? 'visible' : 'hidden';
        // })
    }

    // now play the videos, switching according to the edit list
    videoPlayer.play = function(time){
        videos = element.selectAll('video');
        var time = time || 0;
        timeouts = [];

        videoTracks = tracks.filter(function(track){
            return track.type == 'video';
        })

        editList.forEach(function(edit){
            timeouts.push(setTimeout(function(){
                videoPlayer.showVideo(edit.track, videos);
            }, (edit.start - time) * 1000))
        })

        videos.each(function(d,i){
            var video = this;
            var track = videoTracks[i];

            setTimeout(function(){
                video.currentTime = time - track.startTime;
                video.play();
            }, ((track.startTime - time) * 1000));
        })
    }

    // now play the videos, switching according to the edit list
    videoPlayer.stop = function(){
        videos = element.selectAll('video')

        videos.each(function(){
            this.pause();
        })

        timeouts.forEach(function(id){
            clearTimeout(id);
        })
    }

    // getter/setter for the main element it binds to
    videoPlayer.element = function(_element){
        if (!arguments.length) return element;
        if (typeof(_element) == 'string'){
            _element = d3.select(_element);
        }
        element = _element;
        return videoPlayer;
    }

    return videoPlayer;
}