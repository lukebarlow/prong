var pool = pool || {};

pool.videoSearch = function(selection){
    var dispatch = d3.dispatch('addVideo');
    selection.classed('videoSearch',true);
    selection.append('span').text('Search for your video, or enter a YouTube link');
    selection.append('br');
    var search = selection.append('input')
                    .attr('type','text')
                    .attr('class','videoSearchBox');
    var searchButton = selection.append('button').text('search');
    searchButton.on('click', doSearch);
    var results = selection.append('div');

    var youtubeId = /[\w-]{11}/;
    var youtubeLink = /youtube\.com\/watch\?v=([\w-]{11})/;

    // looks to see if this function is either a youtube id or a youtube link.
    // if it is either of these, it will return the id. Otherwise it will
    // return false
    function youtubeLinkOrId(value){
        if (value == value.match(youtubeId)[0]){ return value } 
        var match = value.match(youtubeLink);
        if (match){ return match[1] };
        return false;
    }

    function drawSingleResult(id){
        var url = 'https://gdata.youtube.com/feeds/api/videos/' + id + '?v=2&alt=jsonc';
        d3.json(url, function(result){
            results.html('');
            results.append('span').attr('class','title').text(result.data.title);
            results.append('img').attr('src',result.data.thumbnail.hqDefault);
            results.append('button')
                .style('float','right')
                .text('add video')
                .on('click', function(){
                    results.html('');
                    search.node().value = '';
                    hideDialog();
                    dispatch.addVideo('y:'+id);
                });
        });
    }

    function doSearch(){
        var value = search.node().value;
        // first see if it looks like this is a youtube id. Examples of what
        // we might match are:
        // http://www.youtube.com/watch?v=vKuqYGgEM0g
        // http://www.youtube.com/watch?v=vKuqYGgEM0g&feature=youtu.be
        // vKuqYGgEM0g
        var id = youtubeLinkOrId(value);
        if (id){
            drawSingleResult(id);
        }
    }

    pool.videoSearch.on = function(type, listener){
        dispatch.on(type, listener);
        return pool.videoSearch;
    }
}