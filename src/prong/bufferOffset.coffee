UserAgent = require('./userAgent')
userAgent = new UserAgent()

offsets = {
    'mp3' : {
        'chrome' : 1057,
        'firefox' : 528
    }
}

module.exports = (url) ->
    type = url.split('.').pop()

    if type of offsets
        if userAgent.browser_name of offsets[type]
            return offsets[type][userAgent.browser_name]

    return 0

