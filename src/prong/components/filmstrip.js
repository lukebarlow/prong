var commonProperties = require('../commonProperties'),
    uid = require('../uid');

module.exports = function(){

    var video; 

    function setup(d, video, canvas, offsetTime, callback){
        var x = filmstrip.x(),
            range = x.range(),
            domain = x.domain(),
            startOffset = d.startTime || 0;

        x = d3.scale.linear().range(range).domain([domain[0] - startOffset, domain[1] - startOffset])

        var height = filmstrip.height(),
            width = filmstrip.width(),
            drawingContext = canvas.node().getContext('2d'),
            startTime = Math.max(x.domain()[0], offsetTime),
            endTime = Math.min(x.domain()[1], video.duration + offsetTime),
            endX = x(endTime),
            aspectRatio = video.videoWidth / video.videoHeight,
            thumbnailWidth = aspectRatio * height,
            drawingWidth = x(endTime) - x(startTime),
            frames = drawingWidth / thumbnailWidth,
            times = d3.range(startTime, endTime, (endTime - startTime) / frames),
            index = 0,
            time;

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
            video.currentTime = time || 0;
        }
        video.addEventListener('seeked', seeked);
        nextFrame();
    }

    function filmstrip(selection){

        var videoNode = video.node();

        selection.each(function(d,i){
            var target = this,
                div = d3.select(this),
                width = filmstrip.width(),
                height = filmstrip.height();

            // we create a hidden video tag, then seek through it and pick out
            // frames to show
            var canvas = div.append('canvas')
                        .attr('height', height)
                        .attr('width',width)
                        .style('position','absolute')
                        .style('left','0px')
                        .attr('class','filmstrip');

            setTimeout(function(){
                if (videoNode.readyState >= videoNode.HAVE_METADATA){
                    setup(d, videoNode, canvas, 0)
                }else{
                    videoNode.addEventListener('loadeddata', function(){
                        setup(d, videoNode, canvas, 0)
                    })
                }
            }, 0)

            var timeline = filmstrip.timeline();

            if (timeline){
                // since it takes a while to redraw the filmstrip, we make sure
                // there's a delay since the last change event
                var lastTimeout = null;

                function redraw(){
                    if (video.node().paused){
                        setup(d, videoNode, canvas, 0);
                        lastTimeout = null;
                    }else{
                        lastTimeout = setTimeout(redraw, 400);
                    }
                }
                
                timeline.on('change.' + uid(), function(){
                    if (lastTimeout){
                        clearTimeout(lastTimeout);
                    }
                    lastTimeout = setTimeout(redraw, 400);       
                })
            }
        });
    }

    filmstrip.video = function(_video){
        if (!arguments.length) return video;
        video = _video;
        return filmstrip;
    }

    return d3.rebind(filmstrip, commonProperties(), 'x', 'width', 'height', 'timeline');
}