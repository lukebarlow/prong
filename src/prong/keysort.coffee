module.exports = (key) ->
    (a,b) ->
        A = a[key]
        B = b[key]
        if A > B then return 1
        if A < B then return -1
        return 0