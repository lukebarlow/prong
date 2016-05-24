###
Converts an HTML File object into a track of the relevant type
and with a loader which will load it correctly
###

qtText = require('./qtText')

nameWithoutExtension = (file) =>
    return file.name.substr(0, file.name.lastIndexOf('.'))

audioDecodeTrack = (file) =>

    name = nameWithoutExtension(file)

    track = {
        name : name,
        type: 'audio'
    }

    loader = (loadingMessage, callback) => 
        loadingMessage.text('parsing file')
        reader = new FileReader()
        reader.onload = =>
            loadingMessage.text('decoding audio')
            track._originalFile = reader.result
            track._originalFileName = file.name
            prong.audioContext().decodeAudioData reader.result, (audioBuffer) =>
                track._buffer = audioBuffer
                track._channel = audioBuffer.getChannelData(0)
                callback()
        reader.readAsArrayBuffer(file)

    track._loader = loader
    return track


textDecodeTrack = (file) =>
    name = nameWithoutExtension(file)

    track = {
        name : name,
        type: 'text'
    }

    loader = (loadingMessage, callback) => 

        console.log('text track loader called')

        loadingMessage.text('parsing file')
        reader = new FileReader()
        reader.onload = =>
            phrases = qtText.parse(reader.result)
            for phrase in phrases
                phrase.time = phrase.start
            track.data = phrases
            callback()

        reader.readAsText(file)

    track._loader = loader
    return track




module.exports = (file) =>
    ending = file.name.split('.').pop()

    switch ending
        when 'mp3', 'm4a', 'wav'
            return audioDecodeTrack(file)
        when 'txt', 'text'
            return textDecodeTrack(file)




