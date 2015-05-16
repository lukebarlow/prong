###
this module does all the preparation of data for rendering waveforms. In the
general case, an arbitrary clip of a buffer can be rendered to a visible
domain. Part of the clip may be obscured, and the clip may have zero in
a different place from the main timeline. The pcm data is also downsampled
to be rendered as quickly as possible.

timeline

 5    6    7    8    9    10 <- Main timeline
 |    |    |    |    |    |
 |------------------------|
 |         2    3    4    |   6 <- Time into wave
 |          ___________________
 |         |                  |
 |          -------------------
 |                        |
 --------------------------

In this example, the clip is defined from seconds 2 to 6 of the buffer,
but is visible from 2 to 5. There are 50 pixels per second. So, the two
part return value will be

data - a 200 element array, giving 50 pixels per second which is seconds
2 - 5 of the audio downsampled

scale - a scale which maps the index within the data array to the pixels
inside the viewable area. In this case it is

0 -> 100
1 -> 101
2 -> 102

In the general case, the downsampling might not be exactly 1 per pixel,
because it is quicker and easier to take the cache data which is closest
to the zoom level, so the indexes may map to fractional pixels.

The parameters passed are

@d - an object which must contain various keys. These include
    d._buffer - the buffer object containing the audio. The only properties
        use are d._buffer.sampleRate and optionally d._buffer.sampleOffset
    d._channel - the channel in the buffer to be rendered
    d.startTime - optional. The point in the main timeline where the clip starts
        in the above example d.startTime == 7. Defaults to 0
    d.clipStart - optional. If given, is the time into the audio file
        where the clip starts. In the above example, d.clipStart == 2. Defaults to 0
    d.clipEnd - optional. The time into the audio file where the clip ends.
        In the above example d.clipEnd == 6

@x - the x scale of the viewable area. The domain will be used to determine
    the viewable area (in seconds) and the range will be used to determine
    the pixels per second, and so the downsampling ratio that needs to be used.
    In the above example x.domain() == [5, 10] and x.range() == [0, 250]

the @return value is [data, scale] as described above

See pcmRendering.spec.coffee for more examples

###

downsampleCache = require('../analysis/downsampleCache')
d3 = require('d3-prong')

domainWidth =  (domain) ->
    return domain[1] - domain[0]


module.exports = (d, x) ->
    # extract some variables

    if d._clip
        channel = d._clip._channel
        buffer = d._clip._buffer
    else
        channel = d._channel
        buffer = d._buffer

    sampleOffset = buffer.sampleOffset or 0
    startTime = d.startTime or 0
    clipStart = d.clipStart or 0
    clipEnd = d.clipEnd or channel.length / buffer.sampleRate

    # calculate the viewed part of the waveform
    visibleDomain = x.domain()
    
    length = clipEnd - clipStart
    viewStart = clipStart + Math.max(visibleDomain[0] - startTime, 0)
    viewEnd = clipEnd - Math.max(startTime + length - visibleDomain[1], 0)
    if viewStart > viewEnd then return [null, null]
    clipOffset = startTime - clipStart

    pixelWidth = domainWidth(x.range()) * (viewEnd - viewStart) / domainWidth(visibleDomain)

    cacheObject = d._clip or d
    [data, samplesPerPixel] = downsampleCache(cacheObject, [viewStart, viewEnd], pixelWidth)

    sampleX = d3.scale.linear()
        .domain([0, data.length])
        .range([x(viewStart + clipOffset), x(viewEnd + clipOffset)])

    return [data, sampleX, samplesPerPixel]
