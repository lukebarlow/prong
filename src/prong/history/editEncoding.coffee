# two way conversion between editList arrays and a short string

frameRate = 15

# round the time to the nearest frame, and to 3 decimal places
roundToFrame = (time) ->
    return d3.round(Math.round(time * frameRate) / frameRate,3)


# expands the number to a full decimal without rounding. This is necessary
# for ffmpeg to get the splicing correct
unround = (time) ->
    return Math.round(time * frameRate) / frameRate


stringify = (editList) ->
    e = (editList.map (edit, i) ->
        a = [edit.track, roundToFrame(edit.start)]
        # we only record the end time if it's different from the start
        # time of the following edit, or if it's the last edit in the list
        if edit.end
            if i == (editList.length - 1) or edit.end != editList[i+1].start
                a.push(roundToFrame(edit.end))

        return a.join(',')
    ).join(';')

    return e


parse = (s) ->
    if (!s) then return [{'track' : 0, start : 0}]
    edits = s.split(';')
    editList = []
    edits.forEach (editData) ->
        b = editData.split(',')
        track = parseInt(b[0])
        start = unround(parseFloat(b[1]))
        edit = {
            'track' : track,
            'start' : start
        }
        if b.length > 2
            edit.end = unround(parseFloat(b[2]))
        
        editList.push(edit)
    
    return editList


module.exports = {
    stringify : stringify # convert from editList to string
    parse : parse # convert from string to editList
}
