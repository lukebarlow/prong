d3 = require('../d3-prong-min')

var pool = pool || {}

pool.videoTrack = function(){

    var apsectRatio,
        width,
        height = 128;

    function setup(video, canvas, offsetTime, callback){
        var x = videoTrack.x();
        var width = videoTrack.width();
        var drawingContext = canvas.node().getContext('2d');
        var startTime = Math.max(x.domain()[0], offsetTime);
        var endTime = Math.min(x.domain()[1], video.duration + offsetTime);
        var endX = x(endTime);
        aspectRatio = video.videoWidth / video.videoHeight;
        var thumbnailWidth = aspectRatio * height;
        
        var drawingWidth = x(endTime) - x(startTime);
        var frames = drawingWidth / thumbnailWidth;

        var times = d3.range(startTime, endTime, (endTime - startTime) / frames);
        var index = 0;
        var time;

        // clear the canvas
        canvas.node().width = canvas.node().width;

        function seeked(){
            var drawX = x(time);
            if ((drawX + thumbnailWidth) < endX){
                drawingContext.drawImage(video, drawX, 0, thumbnailWidth, height);
            }else{
                var fractionToDraw = (endX - drawX) / thumbnailWidth;
                drawingContext.drawImage(video, 0, 0, 
                    video.videoWidth * fractionToDraw, video.videoHeight, 
                    drawX, 0, thumbnailWidth * fractionToDraw, height);
            }
            
            nextFrame();
        }

        function nextFrame(){
            if (index > (times.length - 1)){
                video.removeEventListener('seeked', seeked);
                if (callback) callback();
            }
            time = times[index];
            index++;
            video.currentTime = time;
        }

        video.addEventListener('seeked', seeked);
        nextFrame();
    }


    function videoTrack(selection){
        selection.each(function(d,i){
            
            var target = this;
            var div = d3.select(this);
            var width = videoTrack.width();

            // we create a hidden video tag, then seek through it and pick out
            // frames to show
            var canvas = div.append('canvas')
                        .attr('height',128)
                        .attr('width',width)
                        .style('position','absolute')
                        .style('left','0px')
                        .attr('class','videoTrack');

            

            setTimeout(function(){

                console.log('adding the video element now')

                var video = d3.select('#player').append('video')
                            .attr('width',500)
                            .attr('height',280)
                            //.style('position','absolute')
                            .datum(d)

                video.append('source')
                    .attr('type','video/mp4')
                    .attr('src', d.src).node()

                video = video.node()


                d.player = video

                var preview = div.append('canvas')
                            .attr('height',128)
                            .attr('width',170)
                            .style('position','absolute')
                            .style('left','-200px')
                            .attr('class','videoPreview');

                var previewDrawingContext = preview.node().getContext('2d');

                function afterSetup(){
                    video.addEventListener('timeupdate', function(){
                        previewDrawingContext.drawImage(video, 0, 0, 170, 128)
                    })
                }

                if (video.readyState >= video.HAVE_METADATA){
                    setup(video, canvas, d.startTime, afterSetup)
                }else{
                    video.addEventListener('loadeddata', function(){
                        setup(video, canvas, d.startTime, afterSetup)
                    })
                }

                div.append('div').text(d.name).attr('class','video trackName')

            }, 0)            
        })
    };

    videoTrack.redraw = function(selection){
        selection.each(function(d,i){
            var div = d3.select(this);
            var canvas = div.select('canvas');
            var video = d.player;

            canvas.style('left','0px');

            if (video.readyState >= video.HAVE_METADATA){
                setup(video, canvas, d.startTime)
            }else{
                video.addEventListener('loadeddata', function(){
                    setup(video, canvas, d.startTime)
                })
            }

        });
    }

    return d3.rebind(videoTrack, pool.commonProperties(), 'x', 'width');
}

