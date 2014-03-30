##
# Description
#   Monitor and dispatch build test failure on hudson 
# 
# Dependencies:  
#   none  
#  
# Configuration: 
#   process.env.HUDSON_TEST_MANAGER_URL: The hudson URL 
#   TODO process.env.HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES=15 
#   TODO process.env.HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_WARNING_HOURS=24 
#   TODO process.env.HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_ESCALADE_HOURS=96 
#  
# Commands:
#   hubot Check builds - Trigger a check on latest builds
#   hubot Broadcast failed tests for project {} to room {} - Tell Hubot to broadcast test results to the specified room. 
#   hubot Stop broadcasting failed tests for project {} to room {} - Tell Hubot to stop broadcast test results to the specified room. 
#   hubot Watch failed tests for project {} using build {} - Monitor tests for the specified build which is part of specified project. 
#   hubot Stop watching failed tests of build {} for project {} - Stop monitoring tests for the specified build which is part of specified project.
#   hubot Show test(s) assigned to me - Report tests assigned to you
# 
#   hubot Set manager for project {} to {} - For security reason, must be sent in groupchat 
#   hubot Set {warning|escalade} test fix delay for project {} to {} {hour|day}(s) - Configure warning or escalade threshold. Accepted only if from project manager 
# 
#   hubot Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser} - Assign a test/range/list of tests to a user 
#   hubot Show test (report for project) {} 
# 
# Notes:  
#   This plugin support multiple build for a project. This is usefull if multiple builds are working on the same project  
#   (same codebase/branch) but with different scope. This allows to avoid collision/test assignment duplication. 
#  
# Author:  
#   Manuel Darveau 
#
moment = require 'moment'

sort_util = require './util/sort_util'
HudsonConnection = require( './hudson-test-manager/hudson_connection' )
routes = require( './hudson-test-manager/routes' )
test_manager_util = require( './hudson-test-manager/test_string_parser' )

class HudsonTestManager

  constructor: ( @robot, @backend ) ->
    unless process.env.HUDSON_TEST_MANAGER_URL
      @robot.logger.error 'HUDSON_TEST_MANAGER_URL not set'
      process.exit( 1 )

    # See storeAnnouncement
    @state = {}

    @hudson = new HudsonConnection( process.env.HUDSON_TEST_MANAGER_URL )

    @backend = require( './hudson-test-manager/backend' )( @robot, @hudson ) unless @backend

    # Setup "routes":
    @setupRoutes( robot )

    # Listen in backend
    @backend.on 'testresult', @.processNewTestResult

    @backend.on 'err', ( err ) =>
      console.log "Error in backend: #{err}"

    @backend.start()

  # Setup "jabber" routes
  setupRoutes: ( robot ) ->
    # Tell Hubot to broadcast test results to the specified room.
    robot.respond /check builds/i, ( msg ) =>
      @backend.checkForNewTestRun()

    # Tell Hubot to broadcast test results to the specified room.
    robot.respond routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$, ( msg ) =>
      @handleBroadcastTest msg

    # Tell Hubot to stop broadcast test results to the specified room.
    robot.respond routes.STOP_BROADCASTING_FAILED_TESTS_FOR_PROJECT_$_TO_ROOM_$, ( msg ) =>
      @handleStopBroadcastingFailedTests msg

    # Monitor tests for the specified build which is part of specified project.
    robot.respond routes.WATCH_FAILED_TESTS_FOR_PROJECT_$_USING_BUILD_$, ( msg ) =>
      @handleWatchFailedTests msg

    # Stop monitoring tests for the specified build which is part of specified project.
    robot.respond routes.STOP_WATCHING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$, ( msg ) =>
      @handleStopWatchingTests msg

    # Set the project's manager
    robot.respond routes.SET_MANAGER_FOR_PROJECT_$_TO_$, ( msg ) =>
      @handleSetManager msg

    # Configure warning or escalade threshold. Accepted only if from project manager
    robot.respond routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY, ( msg ) =>
      @handleSetThreshold msg

    # Assign a test/range/list of tests to a user
    robot.respond routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME, ( msg ) =>
      @handleAssignTest msg

    # Display failed test and assignee
    # TODO the "for project" part or the route should be optional
    robot.respond routes.SHOW_TEST_REPORT_FOR_PROJECT_$, ( msg ) =>
      @handleShowTestReportForProject msg

    # Display tests assigned to requesting user
    robot.respond routes.SHOW_TEST_ASSIGNED_TO_ME, ( msg ) =>
      @handleShowTestAssignedToMe msg

  handleBroadcastTest: ( msg ) ->
    project = msg.match[1]
    room = msg.match[2]
    @backend.broadcastTestToRoom project, room
    msg.send( "Will broadcast test failures of #{project} to room #{room}" )

  handleStopBroadcastingFailedTests: ( msg ) ->
    project = msg.match[1]
    @backend.broadcastTestToRoom project, undefined
    msg.send( "Won't broadcast test failures of #{project}" )

  handleWatchFailedTests: ( msg ) ->
    project = msg.match[1]
    build = msg.match[2]
    @backend.watchBuildForProject build, project
    msg.send( "Will watch build #{build} in scope of #{project}" )

  handleStopWatchingTests: ( msg ) ->
    project = msg.match[1]
    build = msg.match[2]
    @backend.stopWatchingBuildForProject build, project
    msg.send( "Won't watch build #{build} in scope of #{project} anymore" )

  handleSetManager: ( msg ) ->
    # For security reason, must be sent in groupchat
    if msg.envelope.user.type == 'groupchat'
      project = msg.match[1]
      manager = msg.match[2]
      @backend.setManagerForProject manager, project
      msg.send( "#{manager} in now manager of project #{project}" )
    else
      msg.reply( "For security reason, setting manager must be sent in group chat" )

  handleSetThreshold: ( msg ) ->
    level = msg.match[1]
    project = msg.match[2]
    amount = msg.match[3]
    unit = msg.match[4]
    try
      @backend.setThresholdForProject project, level, amount, unit
      msg.send( "#{level} set at {#amount} #{unit}" )
    catch err
      msg.reply( "Error: #{err}" )

  handleAssignTest: ( msg ) ->
    testsString = msg.match[1]
    project = msg.match[2] ? @getLastAnnouncement( "#{msg.envelope.user.room}" )?.projectname
    user = msg.match[3]

    unless project
      msg.reply( "For which project? Please send something like 'Assign x,y,z of project Toto to me'" )
      return

    if user.toUpperCase() == "ME"
      user = msg.envelope.user.privateChatJID
    else
      # Map simple usernames to private JID. Not sure if hubot's brain can help here
      brainuser = @robot.brain.userForId user
      if brainuser
        user = brainuser.privateChatJID
    
    unless user
      msg.reply( "Sorry, I don't know user '#{user}'" )
      return

    try
      tests = test_manager_util.parseTestString testsString
      fromRoomName = "#{msg.envelope.user.room}"
      # Resolve test # to test name
      lastannouncement = @getLastAnnouncement( fromRoomName )
      for index, testname of tests
        unless isNaN( testname )
          # If a number, resolve it using last announcement
          if lastannouncement
            tests[index] = lastannouncement.failedtests[ parseInt( testname ) ]
          else
            msg.reply( "Sorry, I could not resolve the test #'#{testname}'. Please specify the full test name." )
            # TODO Resend annnouncement?
            return
        unless tests[index]
          msg.reply( "Sorry, I could not find test '#{testname}'" )
          return

      @backend.assignTests project, tests, user
      msg.reply( "Ack. Tests assigned to #{user.split( '@' )[0]}" )

    catch err
      console.log "Error in assign test '#{testsString}': #{err}"
      msg.reply( "Sorry, I don't understand which tests you would like to get assigned (got '#{testsString}'). Tell me something like: 1, 2-5, com.some.Test. (err:#{err})" )

  #
  # Call back with the test report and store annoucement if sent to a room.
  #
  handleShowTestReportForProject: ( msg ) ->
    projectname = msg.match[1]
    unless @backend.getProjects()[projectname]
      msg.reply "Sorry, I do not know #{projectname}"
      return

    [failedTests, unassignedTests, assignedTests] = @backend.getFailedTests projectname
    [report, announcement] = @buildTestReport( projectname, failedTests, unassignedTests, assignedTests, true )
    msg.send report

    # Only store announcement if sent to a room and it's the project room
    if msg.envelope.user.type == 'groupchat'
      # Check if the room where the message was sent is the room for the project. If not, do not storeAnnouncement
      projectRoomName = @backend.getBroadcastRoomForProject projectname
      if msg.envelope.user.room == projectRoomName
        @storeAnnouncement projectRoomName, projectname, announcement
      else
        console.log "Will not store announcement since 'show test report' command was received in #{msg.envelope.user.room} while the room for the project is #{projectRoomName}"

  #
  # Return tests assigned to requesting user
  #
  handleShowTestAssignedToMe: ( msg ) ->
    user = msg.envelope.user.privateChatJID
    unless user
      msg.reply "Sorry, I do not know you :-P"
      return

    report = ""
    for projectname, projectdetail of @backend.getProjects()
      projectNamePrinted = false
      for testname, testdetail of projectdetail.failedtests
        if testdetail.assigned == user
          unless projectNamePrinted
            report += "Project #{projectname}:\n"
            projectNamePrinted = true
          report += "  #{testdetail.name} since #{moment( testdetail.assignedDate ).fromNow()} (#{testdetail.url})\n"

    msg.send report
        
  #
  # Build a test report.
  # Return [String: test report, announcement{1: testname, 2: testname, ...}]
  #
  buildTestReport: ( project, failedTests, unassignedTests, assignedTests, includeAssignedTests ) ->
    if Object.keys( failedTests ).length == 0
      return [ "No test fail", {} ]

    status = "Test report for #{project}\n"
    testno = 0
    announcement = {}

    for detail in sort_util.getValuesSortedBy( unassignedTests, 'name' )
      status += "    #{++testno} - #{detail.name} is unassigned since #{moment( detail.since ).fromNow()} (#{detail.url})\n"
      announcement[testno] = detail.name
      
    if includeAssignedTests
      for detail in sort_util.getValuesSortedBy( assignedTests, 'name' )
        # TODO detail.assigned is the full JID. It would be nice to keep the full JID but report on the simple name
        status += "    #{++testno} - assigned to #{detail.assigned.split( '@' )[0]} since #{moment( detail.assignedDate ).fromNow()}: #{detail.name} (#{detail.url})\n"
        announcement[testno] = detail.name
    return [ status, announcement ]

  #
  # Process new test result
  # Called when a new test result is available
  #
  processNewTestResult: ( projectname, buildname, fixedTests, newFailedTest, currentFailedTest ) =>
    # If nothing new, shut up
    return unless Object.keys( fixedTests ).length != 0 or Object.keys( newFailedTest ).length != 0

    # Get the broadcast room name for this project
    roomname = @backend.getBroadcastRoomForProject projectname
    return unless roomname

    status = "Test report for #{projectname}\n"
    if Object.keys( fixedTests ).length != 0
      status += "  Fixed test(s):\n"
      for detail in sort_util.getValuesSortedBy( fixedTests, 'name' ) 
        status += "    #{detail.name}:"
        if detail.assigned
          status += " Was assigned to #{detail.assigned}."
        else
          status += " Was not assigned."
        status += " Resolution time: #{moment( detail.since ).from( moment(), true )}.\n"

    if Object.keys( newFailedTest ).length != 0
      testno = 0
      announcement = {}
      status += "  New failure(s):\n"
      for detail in sort_util.getValuesSortedBy( newFailedTest, 'name' )
        status += "    #{++testno} - #{detail.name} (#{detail.url})\n"
        announcement[testno] = detail.name
      @storeAnnouncement roomname, projectname, announcement

    # Trim the last \n
    status = status.trim()

    # Send report to the room
    @sendGroupChatMesssage roomname, status

  # Return the last announcement for a given room name
  # return object:
  #   time: when the last announcement was made
  #   projectname: The project name announced
  getLastAnnouncement: ( roomname ) ->
    return @state[roomname]?.lastannouncement

  getAnnouncement: ( projectname ) ->
    return @state[roomname]?[projectname]

  # Store non persistent state such as conversation and announcements
  # state[roomname]
  #   [projectname]
  #     failedtests: Object key=test #, value=test name
  #   lastannouncement
  #     time: Date
  #     projectname: String
  storeAnnouncement: ( roomname, projectname, tests ) ->
    roomname = @backend.getBroadcastRoomForProject projectname
    @state[roomname]?={}
    @state[roomname].lastannouncement?={}
    @state[roomname].lastannouncement.time = moment()
    @state[roomname].lastannouncement.projectname = projectname
    @state[roomname].lastannouncement.failedtests = tests

  # Notify which tests are not assigned
  # TODO Call after configure threshold *if* tests are still unassigned
  notifyUnassignedTest: ( projectname, to_jid ) ->
    roomname = @backend.getBroadcastRoomForProject projectname
    return unless roomname

    [report, announcement] = @buildTestReport( project, failedTests, unassignedTests, assignedTests, false )
    @storeAnnouncement roomname, projectname, announcement
    sendGroupChatMesssage roomname, report

  # TODO Notify assignee of test fail past warning threshold
  # TODO Notify manager of test fail past escalade threshold
  notifyTestStillFail: ( projectname, to_jid ) ->
    # Failed tests for project {}:
    #- http://... is not assigned and fail since {failSinceDate}
    # or 
    #- http://... was assigned to {username | you} {x hours} ago
    console.log 'todo'

  sendPrivateMesssage: ( to_jid, message ) ->
    envelope =
      user:
        privateChatJID: to_jid
        type: 'chat'
    @robot.send( envelope, message )

  sendGroupChatMesssage: ( to_jid, message ) ->
    envelope =
      room: to_jid
      user:
        type: 'groupchat'
    @robot.send( envelope, message )

module.exports = ( robot, backend ) ->
  new HudsonTestManager( robot, backend )