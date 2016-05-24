d3 = require('d3-prong')

module.exports = (element) ->
    return if typeof(element) == 'string' then d3.select(element) else element