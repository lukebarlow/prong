module.exports = (d, i) ->
    if ('name' of d) then return d.name
    if ('src' of d)
        return d.src.slice(d.src.lastIndexOf('/')+1, d.src.lastIndexOf('.'))
            .replace('_',' ')
    return d.type