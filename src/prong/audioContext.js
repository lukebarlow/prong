var audioContext = null;

module.exports = function(){
    if (audioContext) return audioContext;
    try {
        window.AudioContext = window.AudioContext||window.webkitAudioContext;
        audioContext = new AudioContext();
        return audioContext;
    } catch(e) {
        alert('Web Audio API is not supported in this browser');
    }
}
