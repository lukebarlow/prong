downsampleCache = require('../downsampleCache')
d3 = require('../../d3-prong-min')

# dummy data is 100 seconds long at 100 samples per second
getD = ->
    data = d3.range(10000)
    data.subarray = data.slice
    return {
        _channel: data,
        _buffer: {sampleRate: 100}
    }


describe 'downsampleCache', ->

    it 'returns the same data if pixels = samples', ->
        [data, samplesPerPixel] = downsampleCache(getD(), [0, 100], 10000)
        expect(data).toEqual(d3.range(10000))
        expect(samplesPerPixel).toEqual(1)

    it 'returns a downsampled version', ->
        [data, samplesPerPixel] = downsampleCache(getD(), [0, 100], 100)
        expect(data).toEqual(d3.range(99, 10000, 100))
        expect(samplesPerPixel).toEqual(100)

    it 'will return a specific slice of the downsampled audio', ->
        [data, samplesPerPixel] = downsampleCache(getD(), [50, 100], 50)
        expect(data).toEqual(d3.range(5099, 10000, 100))

    it 'will use the pre-cached data for thinly spaced data', ->
        d = getD()
        [data, samplesPerPixel] = downsampleCache(d, [0, 100], 5)
        expect(data).toEqual(d3.range(999, 10000, 1000))

    it 'will use the cache on subsequent calls', ->
        d = getD()
        [data, samplesPerPixel] = downsampleCache(d, [0, 100], 5)
        expect(data).toEqual(d3.range(999, 10000, 1000))
        #fill the cache with dummy data to check that it is being returned
        d._cache[1000] = d3.range(10).map (d) -> 4
        [data, samplesPerPixel] = downsampleCache(d, [0, 100], 5)
        expect(data).toEqual([4, 4, 4, 4, 4, 4, 4, 4, 4, 4])
