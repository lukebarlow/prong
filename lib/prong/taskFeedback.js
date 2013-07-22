module.exports = function(){

    var taskId,
        socket,
        title,
        dispatch = d3.dispatch('finish');

    function taskFeedback(selection){
        if (!socket) throw "Must set the socket before initialising taskFeedback";
        //element = _element;

        selection = selection.append('div');
        selection
            .attr('class','taskFeedback')
            .transition()
            .duration(0)
            .style('opacity',1);
        selection.append('div').attr('class','title').text(title);
        var stage = selection.append('div').attr('class','stage'),
            progress = selection.append('div').attr('class','progress'),
            progressDone = progress.append('div')
                            .attr('class','progressDone')
                            .style('width','0px'),
            comment = selection.append('div').attr('class','comment');

        var lastMessageTime = null;

        socket.on('taskFeedback',function(options){

            if (options.taskId != taskId){
                return;
            } 

            switch(options.messageType){
                case 'newStage' :
                    stage.text(options.stage);
                    progressDone.transition().duration(0).style('width','0px');
                    comment.text('');
                break;
                case 'comment' :
                    comment.text(options.message);
                break;
                case 'progress' :
                    // some problem with transitioning percentages in d3,
                    // so we figure it out in pixels
                    var width = selection.node().clientWidth;
                    var pixelWidth = width * parseInt(options.message) / 100;
                    var messageTime = new Date();
                    var duration = lastMessageTime ? new Date() - lastMessageTime : 100;
                    var lastMessageTime = messageTime;
                    progressDone
                        .transition()
                        .duration(duration)
                        .style('width',pixelWidth + 'px');
                break;
                case 'done':
                    progressDone.transition().duration(0).style('width','0px');
                    comment.text('');
                    stage.text('finished');
                    selection.remove();
                    dispatch.finish();
                break;
                case 'fail':
                    console.log('failure')
                    stage.text(options.message);
                    comment.text('');
                    selection
                        .transition()
                        .delay(2000)
                        .duration(1000)
                        .style('opacity',0)
                        .remove();
                break;
            }
        });
    }

    // getter and setter for the taskId
    taskFeedback.title = function(_title){
        if (!arguments.length) return title;
        title = _title;
        return taskFeedback;
    }

    // getter and setter for the taskId
    taskFeedback.taskId = function(_taskId){
        if (!arguments.length) return taskId;
        taskId = _taskId;
        return taskFeedback;
    }

    // getter and setter for the socket
    taskFeedback.socket = function(_socket){
        if (!arguments.length) return socket;
        socket = _socket;
        return taskFeedback;
    }

    /* for attaching event listeners */
    taskFeedback.on = function(type, listener){
        dispatch.on(type, listener);
        return taskFeedback;
    }

    return taskFeedback;
}