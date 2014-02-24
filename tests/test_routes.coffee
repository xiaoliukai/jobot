process.env.HUDSON_TEST_MANAGER_URL = "Some url..."

routes = require( '../scripts/hudson-test-manager/routes' )
assert = require( 'assert' )

RegExp.prototype.match = ( text, expectedMatches... ) ->
  this.testRoute( text, true, expectedMatches)
  
RegExp.prototype.dontMatch = ( text, expectedMatches... ) ->
  this.testRoute( text, false, expectedMatches)

RegExp.prototype.testRoute = ( text, shouldMatch, expectedMatches ) ->
  results = text.match @
  
  if results
    # Fail if match and should not
    assert.fail(results, false, "Didn't expected a match for '#{text}' on '#{@}'") unless shouldMatch
    
    for match, index in results[1..]
      assert.strictEqual( match, expectedMatches[index], "Expected '#{expectedMatches[index]}' at index #{index} but got '#{match}' for '#{text}' on '#{@}'")
      
  else
    # Fail if no match but should
    assert.fail(results, true, "Expected a match for '#{text}' on '#{@}'") unless not shouldMatch
  

routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$.match 'Broadcast failed tests for project myproject to room myroom', 'myproject', 'myroom'
routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$.match 'Broadcast failed tests for project my_project to room my_room', 'my_project', 'my_room'
routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$.match 'Broadcast failed tests for project my_project.version-branch to room my_room', 'my_project.version-branch', 'my_room'

routes.STOP_BROADCASTING_FAILED_TESTS_FOR_PROJECT_$_TO_ROOM_$.match 'Stop broadcasting failed tests for project myproject to room myroom', 'myproject', 'myroom'

routes.WATCH_FAILED_TESTS_FOR_PROJECT_$_USING_BUILD_$.match 'Watch failed tests for project myproject using build thebuild', 'myproject', 'thebuild' 

routes.STOP_WATCHING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$.match 'Stop watching failed tests of build myproject for project thebuild', 'myproject', 'thebuild'

routes.SET_MANAGER_FOR_PROJECT_$_TO_$.match 'Set manager for project myproject to mdarveau@jabber.8d.com', 'myproject', 'mdarveau@jabber.8d.com'
routes.SET_MANAGER_FOR_PROJECT_$_TO_$.match 'Set manager for project myproject to mdarveau', 'myproject', 'mdarveau'

routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.match 'Set warning test fix delay for project myproject to 5 hour', 'warning', 'myproject', '5', 'hour'
routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.match 'Set warning test fix delay for project myproject to 5 hours', 'warning', 'myproject', '5', 'hour'
routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.match 'Set escalade test fix delay for project myproject to 5 day', 'escalade', 'myproject', '5', 'day'
routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.match 'Set escalade test fix delay for project myproject to 5 days', 'escalade', 'myproject', '5', 'day'
routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.dontMatch 'Set invalid test fix delay for project myproject to 5 days'
routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY.dontMatch 'Set escalade test fix delay for project myproject to 5 millis'

routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1 of project myproject to me', '1', 'myproject', 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1 of project myproject to mdarveau', '1', 'myproject', 'mdarveau'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1 to me', '1', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1,2,3 to me', '1,2,3', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1, 2 to me', '1, 2', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1-2 to me', '1-2', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign com.eightd.8d.com.SomeTest to me', 'com.eightd.8d.com.SomeTest', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign com.eightd.8d.com.SomeTest, com.eightd.8d.com.SomeOtherTest to me', 'com.eightd.8d.com.SomeTest, com.eightd.8d.com.SomeOtherTest', undefined, 'me'
routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME.match 'Assign 1,com.eightd.8d.com.SomeTest, [1-8] to me', '1,com.eightd.8d.com.SomeTest, [1-8]', undefined, 'me'

routes.SHOW_TEST_REPORT_FOR_PROJECT_$.match 'Show test report for project myproject', 'myproject'

console.log "Test passed"