downsample = require('../downsample')
d3 = require('d3-prong')

data = d3.range(12)

describe 'downsample', ->

    it 'produces a thinned version of the data, with the max of every 4 samples', ->
        result = downsample(data, 4)
        expect(result).toEqual([3, 7, 11])


    it 'works with thinning ratios which are not a factor of the data length', ->
        result = downsample(data, 5)
        expect(result).toEqual([4, 9])


    it 'returns the same data if the thinning ratio is 1', ->
        result = downsample(data, 1)
        expect(result).toEqual([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])


    it 'can take the first sample rather than the maximum in each group (the default)', ->
        result = downsample(data, 4, 'first')
        expect(result).toEqual([0, 4, 8])


    it 'works with custom aggregators passed in', ->
        result = downsample(data, 4, d3.mean)
        expect(result).toEqual([1.5, 5.5, 9.5])