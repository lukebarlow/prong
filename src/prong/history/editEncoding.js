// two way conversion between editList arrays and a short string

module.exports = {
    stringify : stringify, // convert from editList to string
    parse : parse // convert from string to editList
}

function stringify(editList){
    var e = editList.map(function(edit, i){
        var a = [edit.track, d3.round(edit.start,3)];
        // we only record the end time if it's different from the start
        // time of the following edit, or if it's the last edit in the list
        if (edit.end){
            if ((i == (editList.length - 1))
                || (edit.end != editList[i+1].start)){
                a.push(d3.round(edit.end,3));
            }
        }
        return a.join(',');
    }).join(';');

    return e;
}

function parse(s){
    if (!s) return [{'track' : 0, start : 0}];
    var edits = s.split(';');
    var editList = [];
    edits.forEach(function(editData){
        var b = editData.split(',');
        var track = parseInt(b[0]);
        var start = parseFloat(b[1]);
        var edit = {
            'track' : track,
            'start' : start
        }
        if (b.length > 2){
            edit.end = parseFloat(b[2])
        }
        editList.push(edit);
    });

    return editList;
}

