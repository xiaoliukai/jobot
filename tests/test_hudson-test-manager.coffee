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
# handleShowTestReportForProject
#
[robot, backend, manager] = setup()
msg = 
  match: [undefined, 'projectA']
  envelope:
    user:
      type: 'groupchat'
      room: 'myconf@conferences.jabber.com'
      name: 'john'
  send: ( msg ) ->
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
unassignedTests = {}
unassignedTests['com.test2'] =
  name: 'com.test2'
  since: moment()
  url: 'http://hudson.acme.com/com.test2'
unassignedTests['com.test1'] =
  name: 'com.test1'
  since: moment()
  url: 'http://hudson.acme.com/com.test1'
assignedTests = {}
assignedTests['com.test3'] =
  name: 'com.test3'
  since: moment()
  url: 'http://hudson.acme.com/com.test3'
  assigned: 'johndoe'
  assignedDate: moment()
failedTests = {}
failedTests['com.test1'] = unassignedTests['com.test1']
failedTests['com.test2'] = unassignedTests['com.test2']
failedTests['com.test3'] = assignedTests['com.test3']
  
[status, announcement] = manager.buildTestReport 'projectA', failedTests, unassignedTests, assignedTests, true
assert status
assert.equal Object.keys( announcement ).length, 3
assert.equal announcement[1], 'com.test1'
assert.equal announcement[2], 'com.test2'
assert.equal announcement[3], 'com.test3'

[status, announcement] = manager.buildTestReport 'projectA', failedTests, unassignedTests, assignedTests, false
assert status
assert.equal Object.keys( announcement ).length, 2
assert.equal announcement[1], 'com.test1'
assert.equal announcement[2], 'com.test2'

#
# processNewTestResult
#
[robot, backend, manager] = setup()

backend.getBroadcastRoomForProject = () ->
  return "roomA"
  
fixedTests = {}
fixedTests['com.fixed'] =
  name: 'com.fixed'
  since: moment()
  url: 'http://hudson.acme.com/com.test1'
  assigned: 'johndoe'
  assignedDate: moment()
newFailedTest = {}
newFailedTest['com.new.fail'] =
  name: 'com.new.fail'
  since: moment()
  url: 'http://hudson.acme.com/com.new.fail'
  
manager.storeAnnouncement = ( roomname, projectname, announcement ) ->
  assert.equal "roomA", roomname
  assert.equal "projectA", projectname
  assert.equal Object.keys( announcement ).length, 1
  assert.equal announcement[1], 'com.new.fail'
  
manager.sendGroupChatMesssage = ( roomname, status ) ->
  assert.equal "roomA", roomname
  assert.equal status.split('\n').length, 5
  
manager.processNewTestResult "projectA", "buildA", fixedTests, newFailedTest
  
#
# handleAssignTest
#
[robot, backend, manager] = setup()

backend.assignTests = ( project, tests, user ) ->
  assert.equal project, 'projectA'
  assert.equal user, 'johndoe@jabber.com'
  assert.equal tests.length, 6
  assert.equal tests[0], 'com.test1'
  assert.equal tests[1], 'com.test2'
  assert.equal tests[2], 'com.test3'
  assert.equal tests[3], 'com.test4'
  assert.equal tests[4], 'com.test5'
  assert.equal tests[5], 'com.test6'
    
manager.getLastAnnouncement = ( roomname ) ->
  assert.equal roomname, 'roomA@conferences.jabber.com'
  tests = {}
  tests[1] = 'com.test1'
  tests[2] = 'com.test2'
  tests[3] = 'com.test3'
  tests[4] = 'com.test4'
  tests[5] = 'com.test5'
  tests[6] = 'com.test6'
  return {} = 
    projectname: 'projectA'
    failedtests: tests
    
msg = 
  match: [undefined, '1,2,3-5,com.test6', undefined, 'me']
  envelope:
    user:
      type: 'groupchat'
      room: 'roomA@conferences.jabber.com'
      name: 'john'
      privateChatJID: 'johndoe@jabber.com'
  reply: ( msg ) ->
    assert.equal msg, 'Ack. Tests assigned to johndoe'
manager.handleAssignTest msg  

#
# handleAssignTest
#
[robot, backend, manager] = setup()
backend.getProjects = ( project, tests, user ) ->
  projects = {}
  projects['projectA'] = {}
  projects['projectA'].failedtests = {}
  projects['projectA'].failedtests['com.test1'] =
    name: 'com.test1'
    assigned: 'johndoe@jabber.com'
    assignedDate: moment()
    url: 'some url'
  return projects

msg = 
  match: [undefined, 'show tests assigned to me']
  envelope:
    user:
      type: 'chat'
      privateChatJID: 'johndoe@jabber.com'
  send: ( msg ) ->
    assert.equal msg, 'Project projectA:\n  com.test1 since a few seconds ago (some url)\n'
manager.handleShowTestAssignedToMe msg

console.log "Success"