assert = require( 'assert' )

util = require( '../scripts/hudson-test-manager/util' )

assertParseTestString = ( text, expectedTests... ) ->
  tests = util.parseTestString text
  assert.equal Object.keys( tests ).length, expectedTests.length
  for test, index in tests
    assert.strictEqual( test, expectedTests[index], "Expected '#{expectedTests[index]}' at index #{index} but got '#{test}' for '#{text}'" )

assertInvalidTestString = ( text ) ->
  assert.throws( ()->
    util.parseTestString text
    , Error );
      
#Test single elements
assertParseTestString '1', 1
assertParseTestString '1,2', 1, 2
assertParseTestString '1 ,2', 1, 2
assertParseTestString '1,2 ', 1, 2

# Test range
assertParseTestString '1-2', 1, 2
assertParseTestString '2-4', 2, 3, 4

# Test name
assertParseTestString 'com.eightd.test.one', 'com.eightd.test.one'
assertParseTestString 'com.eightd.test.one,com.eightd.test.two', 'com.eightd.test.one', 'com.eightd.test.two'

# Test combo
assertParseTestString '1,2,3-5,com.eightd.test.nine,10', 1, 2, 3, 4, 5, 'com.eightd.test.nine', 10

assertInvalidTestString '1-a'

console.log "Success"