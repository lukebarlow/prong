audioContext = null;

module.exports = ->
    if audioContext then return audioContext
    try
        window.AudioContext = window.AudioContext||window.webkitAudioContext
        audioContext = new AudioContext()
        return audioContext
    catch e
        alert('Web Audio API is not supported in this browser')