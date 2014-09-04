# sets up a getter, setter and change listener for a particular 
# parameter in the url hash string
module.exports = (id, codec) ->

    
    dispatch = d3.dispatch('change')
    history = {}
    suppressEvents = false;

    # based on code from // from http://stackoverflow.com/questions/5999118/add-or-update-query-string-parameter
    history.get = () ->
        hash = unescape(window.location.hash)
        re = new RegExp("[#|&]" + id + "=(.*?)(&|$)", "i")
        separator = if hash.indexOf('#') != -1 then "&" else "#"
        match = hash.match(re)
        value = if match then match[1] else null
        if (codec) then value = codec.parse(value)
        return value


    # set the given value on this history token. If a codec is present, then
    # the value will be stringified with the codec first.
    # The description is used to temporarily set the title of the browser
    # while changing the url, so this title will show up in history
    history.set = (value, description) ->
        if (codec) then value = codec.stringify(value)
        suppressEvents = true
        hash = unescape(window.location.hash)
        re = new RegExp("([#|&])" + id + "=.*?(&|$)", "i")
        separator = if hash.indexOf('#') != -1 then "&" else "#"
        if hash.match(re)
            hash = hash.replace(re, '$1' + id + "=" + value + '$2')
        else
            hash += separator + id + "=" + value
        
        currentTitle = window.document.title
        if (description) then window.document.title = currentTitle + ' - ' + description
        window.location.hash = hash
        if (description) then window.document.title = currentTitle
        suppressEvents = false
    

    later = ->
        popstateListener = (e) ->
            if not suppressEvents
                newValue = get()
                if (newValue != current)
                    dispatch.change(newValue)

        window.addEventListener("popstate", popstateListener, false)
            
    setTimeout(later, 1)


    history.on = (type, listener) ->
        dispatch.on(type, listener)
        return history
    
    return history
