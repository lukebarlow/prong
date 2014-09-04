# take from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
# used to create random globally unique ids, for cases such as secret links

s4 = -> Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)

module.exports = -> s4() + s4()