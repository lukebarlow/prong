# from http://stackoverflow.com/questions/3231459/create-unique-id-with-javascript
module.exports = (
    ->
        id = 0
        return ->
            if(arguments[0]==0)
                id = 0
            return id++
)()