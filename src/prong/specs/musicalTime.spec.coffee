MusicalTime = require('../musicalTime')

getSampleData = -> [
        {
            numerator : 4,
            denominator : 4,
            numberOfBars : 2,
            tempo : 120,
            startTime : 5
        },
        {
            numerator : 3,
            denominator : 4,
            numberOfBars : 2
        },
        {
            numerator : 7,
            denominator : 8,
            numberOfBars : 1
        },
        {
            numerator : 2,
            denominator : 4,
            numberOfBars : 4,
            tempo : 150
        },
        {
            numerator : 2,
            denominator : 4,
            numberOfBars : 4,
            tempo : 120
        }
    ]
    

getInvalidData = -> {
    startTime : 5,
    bars : [
            {
                numerator : 4,
                denominator : 4,
                numberOfBars : 2
                # no tempo in the first chunk. should throw an error
            }
        ]
    }


describe 'musicalTime', ->

    it 'works out the tempo for each section when you set data', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.bars[1].tempo).toEqual(120)

    it 'modifies the tempo if the denominator changes', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.bars[2].tempo).toEqual(240)

    it 'allows you to manually change the tempo for a new chunk', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.bars[3].tempo).toEqual(150)

    it 'throws an exception if the first chunk does not have tempo specified', ->
        expect( -> new MusicalTime(getInvalidData())).toThrow()

    it 'works out the start time for each chunk', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.bars[0].startTime).toEqual(5)
        expect(musicalTime.bars[1].startTime).toEqual(9)
        expect(musicalTime.bars[2].startTime).toEqual(12)
        expect(musicalTime.bars[3].startTime).toEqual(13.75)
        expect(musicalTime.bars[4].startTime).toEqual(16.95)

    it 'works out the start bar number for each chunk', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.bars[0].startBarNumber).toEqual(1)
        expect(musicalTime.bars[1].startBarNumber).toEqual(3)
        expect(musicalTime.bars[2].startBarNumber).toEqual(5)
        expect(musicalTime.bars[3].startBarNumber).toEqual(6)
        expect(musicalTime.bars[4].startBarNumber).toEqual(10)

    it 'works out the end time for the sequence of bars', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.endTime).toEqual(20.95)

    it 'works out the number for the last bar in the whole sequence', ->
        data = getSampleData()
        musicalTime = new MusicalTime(data)
        expect(musicalTime.finalBarNumber).toEqual(13)


