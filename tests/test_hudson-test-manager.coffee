assert = require 'assert'

robot = 
  respond: () ->
    return

backend =
  start: () ->
    return
  on: () ->
    return

process.env.HUDSON_TEST_MANAGER_URL = 'http://www.test.com'
    
manager = require( '../scripts/hudson-test-manager' )( robot, backend )

#
# Test handleShowTestReportForProject
#
msg = 
  match: [undefined, 'projectA']
  envelope:
    user:
      type: 'groupchat'
      room: 'myconf'
      name: 'conferences.jabber.com'
  reply: ( msg ) ->
    assert.equal msg, 'Test report for'
backend.getProjects = () ->
  projects = {}
  projects['projectA'] = {}
  return projects
backend.getBroadcastRoomForProject = ( projectname ) ->
  assert.equal projectname, 'projectA'
  return 'myconf@conferences.jabber.com'
backend.getFailedTests = ( projectname ) ->
  assert.equal projectname, 'projectA'
  return [undefined, undefined, undefined]
manager.buildTestReport = () ->
  tests = {}
  tests[0] = 'com.test1'
  tests[1] = 'com.test2'
  tests[2] = 'com.test3'
  return ['Test report for', tests]
  
manager.handleShowTestReportForProject msg
assert.equal manager.state['myconf@conferences.jabber.com'].lastannouncement.projectname, 'projectA'
assert.equal manager.state['myconf@conferences.jabber.com'].lastannouncement.failedtests[0], 'com.test1'
assert.equal manager.state['myconf@conferences.jabber.com'].lastannouncement.failedtests[1], 'com.test2'
assert.equal manager.state['myconf@conferences.jabber.com'].lastannouncement.failedtests[2], 'com.test3'

#
# buildTestReport
#
# TODO Implement

#
# processNewTestResult
#
# TODO Implement


console.log "Success"