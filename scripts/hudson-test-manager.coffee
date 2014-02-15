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
#   Broadcast failed tests for project {} to room {} - Tell Hubot to broadcast test results to the specified room. 
#   Stop broadcasting failed tests for project {} to room {} - Tell Hubot to stop broadcast test results to the specified room. 
#   Watch failed tests for project {} using build {} - Monitor tests for the specified build which is part of specified project. 
#   Stop watching failed tests of build {} for project {} - Stop monitoring tests for the specified build which is part of specified project. 
# 
#   Set manager for project {} to {} - For security reason, must be sent in groupchat 
#   Set {warning|escalade} test fix delay for project {} to {} {hour|day}(s) - Configure warning or escalade threshold. Accepted only if from project manager 
# 
#   Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser} - Assign a test/range/list of tests to a user 
#   Show test report for project {} 
# 
# Notes:  
#   This plugin support multiple build for a project. This is usefull if multiple builds are working on the same project  
#   (same codebase/branch) but with different scope. This allows to avoid collision/test assignment duplication. 
#  
# Author:  
#   Manuel Darveau 
#
util = require( 'util' )
HudsonConnection = require( './hudson-test-manager/hudson_connection' )

routes = require( './hudson-test-manager/routes' )
test_manager_util = require( './hudson-test-manager/util' )

class HudsonTestManager

  constructor: ( @robot ) ->
    unless process.env.HUDSON_TEST_MANAGER_URL
      @robot.logger.error 'HUDSON_TEST_MANAGER_URL not set'
      process.exit( 1 )

    # See storeAnnouncement
    @state = {}

    @hudson = new HudsonConnection( process.env.HUDSON_TEST_MANAGER_URL )

    @backend = require( './hudson-test-manager/backend' )( @robot )

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
    robot.respond routes.BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$, ( msg ) =>
      project = msg.match[1]
      room = msg.match[2]
      @backend.broadcastTestToRoom project, room
      msg.reply( "Will broadcast test failures of #{project} to room #{room}" )

    # Tell Hubot to stop broadcast test results to the specified room.
    robot.respond routes.STOP_BROADCASTING_FAILED_TESTS_FOR_PROJECT_$_TO_ROOM_$, ( msg ) =>
      project = msg.match[1]
      @backend.broadcastTestToRoom project, undefined
      msg.reply( "Won't broadcast test failures of #{project}" )

    # Monitor tests for the specified build which is part of specified project.
    robot.respond routes.WATCH_FAILED_TESTS_FOR_PROJECT_$_USING_BUILD_$, ( msg ) =>
      project = msg.match[1]
      build = msg.match[2]
      @backend.watchBuildForProject build, project
      msg.reply( "Will watch build #{build} in scope of #{project}" )

    # Stop monitoring tests for the specified build which is part of specified project.
    robot.respond routes.STOP_WATCHING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$, ( msg ) =>
      project = msg.match[1]
      build = msg.match[2]
      @backend.stopWatchingBuildForProject build, project
      msg.reply( "Won't watch build #{build} in scope of #{project} anymore" )

    # Set the project's manager
    robot.respond routes.SET_MANAGER_FOR_PROJECT_$_TO_$, ( msg ) =>
      # For security reason, must be sent in groupchat
      if msg.envelope.user.type == 'groupchat'
        project = msg.match[1]
        manager = msg.match[2]
        @backend.setManagerForProject manager, project
        msg.reply( "#{manager} in now manager of project #{project}" )
      else
        msg.reply( "For security reason, setting manager must be sent in group chat" )

    # Configure warning or escalade threshold. Accepted only if from project manager
    robot.respond routes.SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY, ( msg ) =>
      level = msg.match[1]
      project = msg.match[2]
      amount = msg.match[3]
      unit = msg.match[4]
      try
        @backend.setThresholdForProject project, level, amount, unit
        msg.reply( "#{level} set at {#amount} #{unit}" )
      catch err
        msg.reply( "Error: #{err}" )

    # Assign a test/range/list of tests to a user
    robot.respond routes.ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME, ( msg ) =>
      testsString = msg.match[1]
      project = msg.match[2] ? @getLastAnnouncement( msg.envelope.user.room )
      user = msg.match[3]

      unless project
        msg.reply( "For which project? Please send something like 'Assign x,y,z of project Toto to me'" )
        return

      if user == "Me"
        user = msg.envelope.user.privateChatJID
      else
        # TODO Map simple usernames to private JID. Not sure if hubot's brain can help here
        user = msg.envelope.user.privateChatJID

      unless user
        msg.reply( "Sorry, I don't know user '#{user}'" )
        return

      try
        tests = test_manager_util.parseTestString testsString
        fromRoomName = "#{msg.envelope.user.room}@#{msg.envelope.user.name}"
        # Resolve test # to test name 
        for index, testname of tests
          # FIXME "is number" and "to_int" is not coffeescript...
          if testname is number
            tests[index] = @state[fromRoomName].lastannouncement.failedtests[to_int(testname)]
            unless tests[index]
              msg.reply( "Sorry, I could not find test '#{testname}'" ) 
              return

        @backend.assignTests project, tests, user
        msg.reply( "Ack. Tests assigned to #{user}" )
        
      catch err
        console.log "Could not parse '#{testsString}': #{err}"
        msg.reply( "Sorry, I don't understand which tests you would like to get assigned (got '#{testsString}'). Tell me something like: 1, 2-5, com.some.Test" )

    # Display failed test and assignee
    robot.respond routes.SHOW_TEST_REPORT_FOR_PROJECT_$, ( msg ) =>
      project = msg.match[1]
      unless @backend.getProjects[project]
        msg.reply "Sorry, I do not know #{project}"
        return

      [failedTests, unassignedTests, assignedTests] = @backend.getFailedTests project
      [report, announcement] = @buildTestReport( project, failedTests, unassignedTests, assignedTests, true )
      msg.reply( report )
      if msg.envelope.user.type == 'groupchat'
        # Check if the room where the message was sent is the room for the project. If not, do not storeAnnouncement
        fromRoomName = "#{msg.envelope.user.room}@#{msg.envelope.user.name}"
        projectRoomName = @backend.getBroadcastRoomForProject projectname
        if fromRoomName == projectRoomName
          @storeAnnouncement projectRoomName, projectname, announcement
        else 
          console.log "Will not store announcement since 'show test report' command was received in #{fromRoomName} while the room for the project is #{projectRoomName}"

  #
  # Build a test report.
  # Return [String: test report, announcement{1: testname, 2: testname, ...}]
  #
  buildTestReport: ( project, failedTests, unassignedTests, assignedTests, includeAssignedTests ) ->
    status = "Test report for #{project}\n"
    testno = 0
    announcement = {}
    for testname, detail of unassignedTests
      status += "    #{++testno} - #{detail.name} is unassigned since #{detail.since} (#{detail.url})\n"
      announcement[testno] = testname
    if includeAssignedTests
      for testname, detail of assignedTests
        status += "    #{++testno} - assigned to (#{detail.assigned} since #{detail.assignedDate}): #{detail.name} (#{detail.url})\n"
        announcement[testno] = testname
    return [ status, announcement ]

  #
  # Process new test result
  # Called when a new test result is available
  #
  processNewTestResult: ( projectname, buildname, fixedTests, newFailedTest, currentFailedTest ) ->
    # If nothing new, shut up
    return unless Object.keys( fixedTests ).length != 0 or Object.keys( newFailedTest ).length != 0

    # Get the broadcast room name for this project
    roomname = @backend.getBroadcastRoomForProject projectname
    return unless roomname
    
    status = "Test report for #{project}\n"
    if Object.keys( fixedTests ).length != 0
      status += "  Fixed tests:"
      for testname, detail of fixedTests
        status += "    #{detail.name}:"
        if detail.assigned
          status += " Was assigned to #{detail.assigned}."
        else
          status += " Was not assigned."
        status += " Failure to resolution: #{moment().diff( detail.since, 'days', true )}."

    if Object.keys( newFailedTest ).length != 0
      testno = 0
      announcement = {}
      status += "  New failures:"
      for testname, detail of fixedTests
        status += "    #{++testno} - #{detail.name} (#{detail.url})"
        announcement[testno] = testname
      @storeAnnouncement roomname, projectname, announcement

    # Send report to the room
    sendGroupChatMesssage roomname, report

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
    @state[roomname].lastannouncement.time = new Date()
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
      room: to_jid
      user:
        type: 'chat'
    robot.send( envelope, message )

  sendGroupChatMesssage: ( to_jid, message ) ->
    # TODO Validate if this works
    envelope =
      room: to_jid
      user:
        type: 'groupchat'
    robot.send( envelope, message )

module.exports = ( robot ) ->
  new HudsonTestManager( robot )