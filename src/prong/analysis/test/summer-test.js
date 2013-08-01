var assert = require('assert'),
    summer = require('../summer')

describe('Summer', function(){

    var s = summer();
        s.add('fish', 2)
        s.add('fish', 3)
        s.add('cow', 8)

    describe('#add()', function(){
        it('test adding to a summer', function(){
            assert.equal(5, s.get('fish'));
            assert.equal(8, s.get('cow'));
        });
    });

    describe('#most()', function(){
        it('get the highest value from the summer', function(){
            var m = s.most();
            assert.equal('cow', m.key);
            assert.equal(8, m.value);
        });
    });

});


