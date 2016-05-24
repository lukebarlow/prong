module.exports = (d, i) ->
    if ('name' of d and d.name) then return d.name
    if ('src' of d and d.src)
        return d.src.slice(d.src.lastIndexOf('/')+1, d.src.lastIndexOf('.'))
            .replace('_',' ')
    name = d.type
    id = d.id || d.trackId
    if id
      name += ' ' + id
    else
      name += ' ' + i
    return name