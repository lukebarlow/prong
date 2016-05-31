###
 thins out the data by taking chunks of samples at a time
 and applying an aggregating function to them. The aggregator function is
 optional, and will default to one which takes the maximum sample in
 the group of samples. So, for example if thinningFactor = 4
 and aggregator = 'max', then the return value will be an array with 1/4 the
 number of elements, each element being the maximum of a group of 4 of the
 original array.
###



aggregatorByName = {
    'max' : 'max',
    'first' : (d) -> return d[0]
}

downsampleMax = (data, thinningFactor) ->
    thinnedArray = []
    i = -1
    j = 0
    n = data.length
    max = 0
    maxAbs = 0
    while ++i < n
        abs = Math.abs(data[i])
        if abs > maxAbs
            maxAbs = abs
            max = data[i]
        j++
        if j == thinningFactor
            j = 0
            thinnedArray.push(max)
            max = 0
            maxAbs = 0
    return thinnedArray


module.exports = (data, thinningFactor, aggregator = 'max') ->

    if (thinningFactor == 1) then return data

    if aggregator of aggregatorByName
        aggregator = aggregatorByName[aggregator]

    # for max aggregator, we use a custom optimised code path
    if aggregator == 'max'
        return downsampleMax(data, thinningFactor)

    thinnedArray = []
    for i in [0...data.length] by thinningFactor
        thinnedArray.push(aggregator(data.slice(i, i + thinningFactor)))

    return thinnedArray