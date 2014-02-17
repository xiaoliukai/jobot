assert = require 'assert'
moment  = require 'moment'

process.env.HUDSON_TEST_MANAGER_URL = 'http://www.test.com'

setup = () ->
  robot = 
    respond: () ->
      return
  
  backend =
    start: () ->
      return
    on: () ->
      return
      
  manager = require( '../scripts/hudson-test-manager' )( robot, backend )
  
  return [robot, backend, manager]

#
# Test handleShowTestReportForProject
#
[robot, backend, manager] = setup()
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
[robot, backend, manager] = setup()
failedTests = {}
unassignedTests = {}
unassignedTests['com.test1'] =
  name: 'com.test1'
  since: moment()
  url: 'http://hudson.acme.com/com.test1'
assignedTests = {}
assignedTests['com.test2'] =
  name: 'com.test2'
  since: moment()
  url: 'http://hudson.acme.com/com.test2'
  assigned: 'johndoe'
  assignedDate: moment()
  
[status, announcement] = manager.buildTestReport 'projectA', failedTests, unassignedTests, assignedTests, true
assert status
assert.equal Object.keys( announcement ).length, 2
assert.equal announcement[1], 'com.test1'
assert.equal announcement[2], 'com.test2'

[status, announcement] = manager.buildTestReport 'projectA', failedTests, unassignedTests, assignedTests, false
assert status
assert.equal Object.keys( announcement ).length, 1
assert.equal announcement[1], 'com.test1'

  #
  #buildTestReport: ( project, failedTests, unassignedTests, assignedTests, includeAssignedTests ) ->
  #  status = "Test report for #{project}\n"
  #  testno = 0
  #  announcement = {}
  #  for testname, detail of unassignedTests
  #    status += "    #{++testno} - #{detail.name} is unassigned since #{detail.since} (#{detail.url})\n"
  #    announcement[testno] = testname
  #  if includeAssignedTests
  #    for testname, detail of assignedTests
  #      status += "    #{++testno} - assigned to (#{detail.assigned} since #{detail.assignedDate}): #{detail.name} (#{detail.url})\n"
  #      announcement[testno] = testname
  #  return [ status, announcement ]

#
# processNewTestResult
#
# TODO Implement


console.log "Success"