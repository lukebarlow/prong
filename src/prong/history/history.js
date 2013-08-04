// sets up a getter, setter and change listener for a particular 
// parameter in the url hash string
module.exports = function(id){

    var current = get();
    var dispatch = d3.dispatch('change');
    var history = {
        get : get,
        set : set,
        on : on
    }
    var suppressEvents = false;

    // based on code from // from http://stackoverflow.com/questions/5999118/add-or-update-query-string-parameter
    function get(){
        var hash = unescape(window.location.hash)
        var re = new RegExp("[#|&]" + id + "=(.*?)(&|$)", "i");
        separator = hash.indexOf('#') !== -1 ? "&" : "#";
        var match = hash.match(re)
        if (match) {
            return match[1];
        }else {
            return false
        }
    }

    function set(value, description){
        suppressEvents = true;
        var hash = unescape(window.location.hash)
        var re = new RegExp("([#|&])" + id + "=.*?(&|$)", "i");
        separator = hash.indexOf('#') !== -1 ? "&" : "#";
        if (hash.match(re)) {
            hash = hash.replace(re, '$1' + id + "=" + value + '$2');
        }else {
            hash += separator + id + "=" + value;
        }
        var currentTitle = window.document.title;
        if (description) window.document.title = currentTitle + ' - ' + description;
        window.location.hash = hash;
        if (description) window.document.title = currentTitle;
        suppressEvents = false;
    }

    setTimeout(function(){
        window.addEventListener("popstate", function(e) {
            if (!suppressEvents){
                var newValue = get();
                if (newValue != current){
                    current = newValue;
                    dispatch.change(newValue);
                }
            }
        }, false);
    }, 1);

    function on(type, listener){
        dispatch.on(type, listener);
        return history;
    }
    
    return history;
}