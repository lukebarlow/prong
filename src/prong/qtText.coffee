d3 = require('d3-time-format')


QT_TIME_FORMAT = '[%H:%M:%S.%L]'
timeFormat = d3.timeFormat(QT_TIME_FORMAT)
_timeParse = d3.timeParse(QT_TIME_FORMAT)
zeroTime = _timeParse('[00:00:00.000]').getTime()
timeParse = (s) => (_timeParse(s).getTime() - zeroTime) / 1000


parse = (text) =>
    lines = text.split(/[\r\n]+/)
    phrases = []

    for i in [1...lines.length] by 3
        if not lines[i].length then continue
        phrases.push({
            start : timeParse(lines[i]),
            text : lines[i+1],
            end : timeParse(lines[i+2])
        })

    return phrases


stringify = (phrases) =>
    console.log('stringify not yet implemented')
    return ''


module.exports = {
    stringify : stringify,
    parse : parse
}