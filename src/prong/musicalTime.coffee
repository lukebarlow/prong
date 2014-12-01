# this ecapsulates the logic required to deal with a sequence of bars each
# with potentially different time signatures and tempos. It maps bars and beats
# to absolute time (in seconds) and vice versa. It can also work with musical
# ticks, which are normally 4096 per crotchet

d3 = require('./d3-prong-min')

class MusicalTime

    MusicalTime.RESOLUTION = 16384 # ticks per brieve i.e. per 4/4 bar
    MusicalTime.barLength = (chunk) -> chunk.numerator * 60 / chunk.tempo


    constructor: (bars) ->
        this.bars = bars
        this._scale = d3.scale.linear()
        this._fleshOutBars()
        

    # returns the bar number and number of units at the given quantize level
    # at the given time. e.g. for quantize = 4, will return the number of the
    # nearest crotchet in the bar. beat is zero based, but bars start at 1
    getBarAndBeatAtTime: (time, quantize) ->
        barTime = this._scale.invert(time)
        bar = ~~barTime
        fractionOfBar = barTime - bar
        [numerator, denominator] = this.getTimeSignatureAtBar(bar)
        quarterNotesPerBar = numerator * 4 / denominator
        beat = Math.round(fractionOfBar * quarterNotesPerBar * (quantize / 4)) / (quantize / 4)
        while beat >= numerator
            beat -= numerator
            bar += 1
        return [bar, beat]


    getTimeSignatureAtBar: (barNumber) ->
        i = 0
        barGroup = this.bars[i]
        while barGroup.startBarNumber < barNumber
            barGroup = this.bars[++i]
        return [barGroup.numerator, barGroup.denominator]


    # returns a d3.scale for mapping ticks to pixels
    ticksToPixels: (x) ->
        domain = this.bars.map (chunk) -> chunk.startTick
        domain.push(this.bars.slice(-1)[0].endTick)
        range = this._scale.range().map(x)
        return d3.scale.linear().domain(domain).range(range)


    # returns a d3.scale for mapping bars to pixels
    barsToPixels: (x) ->
        domain = this._scale.domain()
        range = this._scale.range().map(x)
        return d3.scale.linear().domain(domain).range(range)


    # TODO - switch to using ticks
    beats: (start, duration, quantize) ->
        barTime = this._scale.invert(start)
        duration = this._scale.invert(start + duration) - barTime
        [numerator, denominator] = this.getTimeSignatureAtBar(~~barTime)
        beats = Math.round(duration * numerator * (quantize / 4)) / (quantize / 4)
        if beats < 1 then beats = 1
        return beats


    # calculates attributes such as start and end times for each chunk of bars, 
    # to make future calculations more simple. Returns the end time of the
    # sequence of bars
    _fleshOutBars: () ->

        # make sure the groups of bars have all the additional attributes
        lastDenominator = 4
        tempo = this.bars[0].tempo
        time = this.bars[0].startTime
        if not tempo
            throw 'Must specify tempo for the first group of bars'
        if not time
            throw 'Must specify the start time (in seconds) for the first group of bars'
        barNumber = 1
        tick = 0 # tempo independent scale of musical time
        this.bars.forEach (chunk) -> # chunk may be more than 1 bar
            if not ('tempo' of chunk)
                chunk.tempo = tempo * chunk.denominator / lastDenominator
            tempo = chunk.tempo
            lastDenominator = chunk.denominator
            chunk.startTime = time
            time += chunk.numberOfBars * MusicalTime.barLength(chunk)
            chunk.startBarNumber = barNumber
            barNumber += chunk.numberOfBars
            chunk.startTick = tick
            tick += chunk.numberOfBars * chunk.numerator * MusicalTime.RESOLUTION / chunk.denominator
            chunk.endTick = tick
        this.endTime = time
        this.finalBarNumber = barNumber - 1

        # now update the internal scale
        domain = this.bars.map (chunk) -> chunk.startBarNumber
        domain.push(this.finalBarNumber + 1)
        range = this.bars.map (chunk) -> chunk.startTime
        range.push(this.endTime)
        this._scale.domain(domain).range(range)


module.exports = MusicalTime