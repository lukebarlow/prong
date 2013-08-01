var assert = require('assert'),
    counter = require('../counter')

describe('Counter', function(){

    var c = counter();
        c.add('fish')
        c.add('fish')
        c.add('cow')

    describe('#add()', function(){
        it('test adding to a counter', function(){
            assert.equal(2, c.get('fish'));
            assert.equal(1, c.get('cow'));
        });
    });

    describe('#most()', function(){
        it('get the max value from the counter', function(){
            var m = c.most();
            assert.equal('fish', m.key);
            assert.equal(2, m.value);
        });
    });

});


