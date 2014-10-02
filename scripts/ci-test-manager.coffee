##
# Description
#   Monitor and dispatch build test failure on hudson
#
# Dependencies:
#   none
#
# Configuration:
#   process.env.HUDSON_TEST_MANAGER_URL: The hudson URL
#   FIX process.env.HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES=15
#    process.env.HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_WARNING_HOURS=24
#    process.env.HUDSON_TEST_MANAGER_DEFAULT_FIX_THRESHOLD_ESCALADE_HOURS=96
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
#   hubot Show unassigned tests for (project) {}
#   hubot test report
#
# Notes:
#   This plugin support multiple build for a project. This is usefull if multiple builds are working on the same project
#   (same codebase/branch) but with different scope. This allows to avoid collision/test assignment duplication.
#
# Author:
#   Manuel Darveau
#
moment = require 'moment'
Xmpp = require 'node-xmpp'
sort_util = require './util/sort_util'
CIConnection =  if process.env.HUDSON=='true' then require( './ci-test-manager/hudson_connection' ) else require('./ci-test-manager/teamcity_connection')
routes = require( './ci-test-manager/routes' )
test_manager_util = require( './ci-test-manager/test_string_parser' )

class CITestManager

  constructor: ( @robot, @backend ) ->
    unless process.env.HUDSON_TEST_MANAGER_URL or process.env.TEAMCITY_TEST_MANAGER_URL
      @robot.logger.error 'HUDSON_TEST_MANAGER_URL and TEAMCITY_TEST_MANAGER_URL are not set'
      process.exit( 1 )

    # See storeAnnouncement
    @state = {}

    @hudson = new CIConnection( if process.env.HUDSON=='true' then process.env.HUDSON_TEST_MANAGER_URL else process.env.TEAMCITY_TEST_MANAGER_URL )
    console.log @hudson, process.env.HUDSON
    @backend = require( './ci-test-manager/backend' )( @robot, @hudson ) unless @backend

    # Setup "routes":
    @setupRoutes( robot )

    # Listen in backend
    @backend.on 'testresult', @.processNewTestResult
    @backend.on 'testunassigned', @.notifyUnassignedTest
    @backend.on 'teststillfail', @.notifyTestStillFail
    @backend.on 'err', ( err ) =>
      console.log "Error in backend: #{err}"

    @backend.start()

  # Setup "jabber" routes
  setupRoutes: ( robot ) ->
    # Tell Hubot to broadcast test results to the specified room.
    robot.respond /check builds?/i, ( ) =>
      @backend.loop()
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

    robot.respond routes.TEST_REPORT, ( msg ) =>
      @handleShowTestsReport msg

    # Display tests assigned to requesting user
    robot.respond routes.SHOW_TEST_ASSIGNED_TO_ME, ( msg ) =>
      @handleShowTestAssignedToMe msg

    # Display failed test and assignee
    robot.respond routes.SHOW_TEST_REPORT_FOR_PROJECT_$, ( msg ) =>
      @handleShowTestReportForProject msg

    # Display unassigned tests
    robot.respond routes.SHOW_UNASSIGNED_TEST_FOR_PROJECT_$, ( msg ) =>
      @handleShowUnassignedTests msg

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
    project = msg.match[2]
    build = msg.match[1]
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
    user = msg.match[3].trim()
    unless project
      msg.reply( "For which project? Please send something like 'Assign x,y,z to me'" )
      return

    if user.toUpperCase() == "ME"
      user = msg.envelope.user.privateChatJID
    else
      # Map simple usernames to private JID. Not sure if hubot's brain can help here
      brainuser = @robot.brain.userForId user
      if brainuser
        user = brainuser.privateChatJID

    unless user
      msg.reply( "Sorry, I don't know user '#{msg.match[3]}'. Please use the username as shown in this group chat." )
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


  handleShowTestsReport : ( msg ) ->
    unless @backend.getProjects()
      msg.send "Sorry, I do not know any projects"
      return
    for projectname, projectvalue of @backend.getProjects()
      [failedTests, unassignedTests, assignedTests] = @backend.getFailedTests projectname
      [report, announcement] = @buildTestReport( projectname, failedTests, unassignedTests, assignedTests, true )
      msg.send report

    # Only store announcement if sent to a room and it's the project room
    # if msg.envelope.user.type == 'groupchat'
    #   # Check if the room where the message was sent is the room for the project. If not, do not storeAnnouncement
    #   projectRoomName = @backend.getBroadcastRoomForProject projectname
    #   if msg.envelope.user.room == projectRoomName
    #     @storeAnnouncement projectRoomName, projectname, announcement
    #   else
    #     console.log "Will not store announcement since 'show test report' command was received in #{msg.envelope.user.room} while the room for the project is #{projectRoomName}"
  #
  # Call back with the unassigned test report and store annoucement if sent to a room.
  #
  handleShowUnassignedTests: ( msg ) ->
    projectname = msg.match[1]
    unless @backend.getProjects()[projectname]
      msg.reply "Sorry, I do not know #{projectname}"
      return

    [failedTests, unassignedTests, assignedTests] = @backend.getFailedTests projectname
    [report, announcement] = @buildTestReport( projectname, failedTests, unassignedTests, assignedTests, false )
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
    console.log "Assigned to me"
    user = msg.envelope.user.privateChatJID
    unless user
      msg.reply "Sorry, I do not know you :-P"
      return
    message = new Xmpp.Element( 'message', {} )
    body =  message.c( 'html', {xmlns: 'http://jabber.org/protocol/xhtml-im'} ).c( 'body', {xmlns: 'http://www.w3.org/1999/xhtml'} )
    for projectname, projectdetail of @backend.getProjects()
      projectNamePrinted = false
      for  testdetail, value of projectdetail.failedtests
        if value.assigned is user
          console.log testdetail
          console.log value.assigned
          unless projectNamePrinted
            body.t( "Project #{projectname}:\n").c('br')
            body.c('a',{href: value.url}).t(" #{value.name} since #{moment( value.assignedDate ).fromNow()}\n").c('br') if projectNamePrinted = true

    msg.send message

  #
  # Build a test report.
  # Return [String: test report, announcement{1: testname, 2: testname, ...}]
  #
  buildTestReport: ( project, failedTests, unassignedTests, assignedTests, includeAssignedTests ) ->
    if Object.keys( failedTests ).length == 0
      return [ "Test report for #{project}\nNo test fail", {} ]

    message = new Xmpp.Element( 'message', {} )
    body = message.c( 'html', {xmlns: 'http://jabber.org/protocol/xhtml-im'} ).c( 'body', {xmlns: 'http://www.w3.org/1999/xhtml'} )

    body.t( "Test report for #{project}\n" ).c( 'br' )
    testno = 0
    announcement = {}

    for detail in sort_util.getValuesSortedBy( unassignedTests, 'name' )
      body.t( "  #{++testno} - " ).c( 'a', {href: detail.url} ).t( detail.name ).up().t( ' is ' ).c( 'b' ).t( 'unassigned' ).up()
      body.t( " since #{moment( detail.since ).fromNow()}" ).c( 'br' )
      announcement[testno] = detail.name

    if includeAssignedTests
      for detail in sort_util.getValuesSortedBy( assignedTests, 'name' )
        # TODO detail.assigned is the full JID. It would be nice to keep the full JID but report on the simple name
        body.t( "  #{++testno} - " ).c( 'a', {href: detail.url} ).t( detail.name ).up().t(" assigned to #{detail.assigned.split( '@' )[0]} since #{moment( detail.assignedDate ).fromNow()}" ).c( 'br' )

        announcement[testno] = detail.name
    return [ message, announcement ]

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

    message = new Xmpp.Element( 'message', {} )
    body = message.c( 'html', {xmlns: 'http://jabber.org/protocol/xhtml-im'} ).c( 'body', {xmlns: 'http://www.w3.org/1999/xhtml'} )

    body.t( "Test report for #{projectname}" ).c( 'br' )
    if Object.keys( fixedTests ).length != 0
      body.t( "  Fixed test(s):" ).c( 'br' )
      for detail in sort_util.getValuesSortedBy( fixedTests, 'name' )
        body.t( '    ' ).c( 'a', {href: detail.url} ).t( detail.name ).up()
        if detail.assigned
          body.t( " was assigned to #{detail.assigned}." )
        else
          body.c( 'b' ).t( " was not assigned." )
        body.t( " Resolution time: #{moment( detail.since ).from( moment(), true )}." ).c( 'br' )

    if Object.keys( newFailedTest ).length != 0
      testno = 0
      announcement = {}
      body.t( "  New failure(s):" ).c( 'br' )
      for detail in sort_util.getValuesSortedBy( newFailedTest, 'name' )
        body.t( "    #{++testno} - " ).c( 'a', {href: detail.url} ).t( detail.name ).up().c( 'br' )
        announcement[testno] = detail.name
      @storeAnnouncement roomname, projectname, announcement

    # Send report to the room
    @sendGroupChatMesssage roomname, message

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
  #  Call after configure threshold *if* tests are still unassigned, unassignedsincetest is the list of test that are still unassigned since the timeout.
  notifyUnassignedTest: ( projectname,unassignedsincetest ) =>
    roomname = @backend.getBroadcastRoomForProject projectname
    return unless roomname
    [failedTests, unassignedTests, assignedTests] = @backend.getFailedTests projectname
    [report, announcement] =   @buildTestReport( projectname, failedTests, unassignedsincetest, assignedTests, false )
    @storeAnnouncement roomname, projectname, announcement
    @sendGroupChatMesssage roomname, report

  #  Notify assignee of test fail past warning threshold
  #  Notify manager of test fail past escalade threshold
  notifyTestStillFail: (storage, project, failingtestwarning, failingtestescalade ) =>

     for testname, detail of failingtestwarning
         message = new Xmpp.Element( 'message', {} )
         body = message.c( 'html', {xmlns: 'http://jabber.org/protocol/xhtml-im'} ).c( 'body', {xmlns: 'http://www.w3.org/1999/xhtml'} )
         body.t( " This test still fails : " ).c( 'a', {href: detail.url} ).t( detail.name ).up().t( " since #{moment( detail.assignedDate ).fromNow()}" ).c( 'br' )
         @sendPrivateMesssage(detail.assigned, message) unless detail.notified #message should be sent only once.
         storage.projects[project].failedtests[testname].notified = true

     for testname, detail of failingtestescalade
         message = new Xmpp.Element( 'message', {} )
         body = message.c( 'html', {xmlns: 'http://jabber.org/protocol/xhtml-im'} ).c( 'body', {xmlns: 'http://www.w3.org/1999/xhtml'} )
         body.t( " This test still fails : " ).c( 'a', {href: detail.url} ).t( detail.name ).up().t( "it was assigned to #{detail.assigned} since #{moment( detail.assignedDate ).fromNow()}" ).c( 'br' )
         @sendPrivateMesssage(detail.assigned, message) unless detail.notifiedmanager
         storage.projects[project].failedtests[testname].notifiedmanager = true


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
  new CITestManager( robot, backend )
