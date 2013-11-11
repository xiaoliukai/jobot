process.env.HUDSON_TEST_MANAGER_URL = "Some url..."

routes = require( '../scripts/hudson-test-manager/routes' )
assert = require( 'assert' )

testRouteMatch = ( regex, text, expectedMatches... ) ->
  testRoute(regex, text, true, expectedMatches)
  
testRouteNotMatch = ( regex, text, expectedMatches... ) ->
  testRoute(regex, text, false, expectedMatches)

testRoute = ( regex, text, shouldMatch, expectedMatches ) ->
  results = text.match regex
  
  if results
    # Fail if match and should not
    assert.fail(results, false, "Didn't expected a match for '#{text}' on '#{regex}'") unless shouldMatch
    
    for match, index in results[1..]
      assert.strictEqual( match, expectedMatches[index], "Expected '#{expectedMatches[index]}' at index #{index} but got '#{match}' for '#{text}' on '#{regex}'")
      
  else
    # Fail if no match but should
    assert.fail(results, true, "Expected a match for '#{text}' on '#{regex}'") unless not shouldMatch
  
testRouteMatch( routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$, "Broadcast failed tests for project myproject to room myroom", 'myproject', 'myroom')
testRouteMatch( routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$, "Broadcast failed tests for project my_project to room my_room", 'my_project', 'my_room')

console.log "Test passed"