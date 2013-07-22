var pool = pool || {};

/* this is a simple wrapper around the taskFeedback component, so that when
   a track is being prepared, that taskFeedback can appear in the position of
   the task. A 'videoPreparation' track will look like

   {
     'sourceId' : 'y:vKuqYGgEM0g',
     'taskId' : 'prepare-1234'
   }

    The presence of the taskId parameter is used to determine if the task
    is already running. If it is not present, then the task will be started


*/

pool.videoPreparation = function(){

    var dispatch = d3.dispatch('finish');

    function videoPreparation(selection){
        selection.each(function(d,i){
            if (!d.taskId){
                d.taskId = createTaskId('prepare');
                pool.socket.emit('prepare', d.taskId, d.sourceId);
            }
            var taskFeedback = pool.taskFeedback()
                                    .socket(pool.socket)
                                    .title('Preparing Video')
                                    .taskId(d.taskId);

            // bubble up the finish event
            taskFeedback.on('finish', function(){
                dispatch.finish(d);
            })

            d3.select(this).call(taskFeedback);
        });
    }

    /* for attaching event listeners */
    videoPreparation.on = function(type, listener){
        dispatch.on(type, listener);
        return videoPreparation;
    }

    return videoPreparation;
}