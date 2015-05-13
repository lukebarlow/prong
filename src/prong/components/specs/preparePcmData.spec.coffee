preparePcmData = require('../preparePcmData')
d3 = require('../../d3-prong-min')

# dummy data is 20 seconds long at 100 samples per second
getD = ->
    data = d3.range(2000)
    data.subarray = data.slice
    return {
        _channel: data,
        _buffer: {sampleRate: 100},
        startTime: 7,
        clipStart: 2,
        clipEnd: 6
    }



describe 'preparePcmData', ->

    it 'preparse pcm data for rendering', ->
        x = d3.scale.linear().domain([5, 10]).range([0, 10])
        [data, scale] = preparePcmData(getD(), x)
        expect(data).toEqual(d3.range(249, 500, 50))
        expect(scale.domain()).toEqual([0, 6])
        expect(scale.range()).toEqual([4, 10])


    it 'works when you have more pixels per second', ->
        x = d3.scale.linear().domain([5, 10]).range([0, 100])
        [data, scale] = preparePcmData(getD(), x)
        expect(data).toEqual(d3.range(204, 500, 5))
        expect(scale.domain()).toEqual([0, 60])
        expect(scale.range()).toEqual([40, 100])

