###
A function for caching and retrieving downsampled versions of waveforms. All 
the data and settings are stored as properties of the @d object. It is expected 
to have the following keys

    d._buffer - the audio buffer
    d._channel - the audio channel

This function will make use of d._cache to store downsampled versions of the 
waveform, so that subsequent calls can be returned quicker

@start the time, in seconds', into the clip where the result should start
@end the time in seconds into the clip where the result should end
@pixelWidth the minimum number of samples you want to represent this waveform

###

downsample = require('./downsample')

ZOOM_LEVELS = [5000, 1000]

module.exports = (d, viewDomain, pixelWidth) ->
    [start, end] = viewDomain
    sampleOffset = d._buffer.sampleOffset or 0
    channel = d._channel
    sampleRate = d._buffer.sampleRate
    length = end - start
    # creates a cache on d if it doesn't already exist
    if not ('_cache' of d)
        d._cache = {}
        for level in ZOOM_LEVELS
            d._cache[level] = downsample(channel, level)

    samplesPerPixel = Math.max(~~(length * sampleRate / pixelWidth), 1)
    sampleStart = (start * sampleRate) + sampleOffset
    sampleEnd = (end * sampleRate) + sampleOffset

    # if any of the downsampled caches are higher resolution than
    # need, then return a slice of them
    for level in ZOOM_LEVELS
        if samplesPerPixel > level
            return [d._cache[level].slice(sampleStart / level, sampleEnd / level), level]

    # otherwise do a downsampled version on the fly
    data = channel.subarray(sampleStart, sampleEnd)
    return [downsample(data, samplesPerPixel), samplesPerPixel]