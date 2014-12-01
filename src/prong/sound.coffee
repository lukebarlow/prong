audioContext = require('./audioContext.coffee')()
bufferOffset = require('./bufferOffset')

# modelled on d3.csv() and d3.xhr() as a simple interface to loading sound 
# buffers.
sound = (url, callback, onprogress) ->
    request = new XMLHttpRequest
    request.open('GET', url, true)
    request.responseType = 'arraybuffer'

    request.onload = ->
        s = request.status
        if onprogress
            onprogress('decoding...')
        
        audioContext.decodeAudioData request.response, (buffer) ->
            # sample offset compensates for small timing differences when
            # decoding mp3s in different browsers
            buffer.sampleOffset = bufferOffset(url)
            callback(buffer)
        
    if onprogress
        request.onprogress = (e) ->
            if (e.lengthComputable)
                percent = 100 * e.loaded / e.total
                onprogress('loading (' + parseInt(percent) + '%)')
    
    request.send(null)


# similar to pool.sound, but second parameter is a list of urls, and the
# callback will be called with a list of corresponding buffers when all sounds
# are loaded
sounds = (urls, callback) ->
    buffers = []
    loaded = 0
    urls.forEach (url, i) ->
        sound url, (buffer) ->
            buffers[i] = buffer
            loaded++
            if loaded >= urls.length
                callback(buffers)


module.exports = {
    sound : sound, # load a sound into a buffer
    sounds : sounds # load multiple sounds into multiple buffers
}