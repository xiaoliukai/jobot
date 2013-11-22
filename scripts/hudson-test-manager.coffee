##
# Description
#   Monitor and dispatch build test failure on hudson
#
# Dependencies: 
#   none 
# 
# Configuration:
#   TODO process.env.HUDSON_TEST_MANAGER_URL
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
# Datastructure in brain:
# test-watch
#   ftk-master
#     room: backoffice
#     lastBroadcastDate: date
#     lastBroadcastTests[]: Id used in last broadcast to room. Reset each time a broadcast to room is made
#     lastBroadcastTests[0]: com.eightd.ftk.some.test
#     lastBroadcastTests[1]: com.eightd.ftk.some.other.test
#     manager: mdarveau@jabber.8d.com
#     fix-delay
#       warning: 24h
#       escalade: 96h
#     builds
#       ftk-master-test-bike
#         tests[com.eightd.ftk.some.test]
#           failSinceDate: firstFailDate
#           assignee: jfcroteau - Used assigned to test or undefined if none
#           assignDate: date - When the test was assigned
#         tests[com.eightd.some.other.test]
#           failSinceDate: firstFailDate
#           assignee: null
#   TODO: add history
# 
# Author: 
#   Manuel Darveau
#

util = require( 'util' )
HudsonConnection = require( './hudson-test-manager/hudson_connection' )

class HudtonTestManager

  constructor: ( robot ) ->
    unless process.env.HUDSON_TEST_MANAGER_URL
      robot.logger.error 'HUDSON_TEST_MANAGER_URL not set'
      process.exit( 1 )

    @xmppIdResolver = require( './xmpp-id-resolver' )( robot )
    @hudson = new HudsonConnection( process.env.HUDSON_TEST_MANAGER_URL )

    #
    # Initial technological testing
    #

    # TODO Remove this after initial tests
    robot.respond /.*status for (.*).*/i, ( msg ) ->
      jobName = msg.match[1]
      console.log "Build status requested for #{jobName}"
      hudson.getBuildStatus( jobName, robot.http, ( err, data ) ->
        msg.reply( hudson.errorToString err ) if err
        msg.reply( "#{jobName} (build #{data.number}) is #{data.result}. See #{data.url}" ) if !err )

    # TODO Remove this after initial tests
    robot.respond /.*test report for (.*).*/i, ( msg ) ->
      jobName = msg.match[1]
      console.log "Test report requested for #{jobName}"
      msg.reply( "In progress..." )
      hudson.getTestReport( jobName, robot.http, ( err, data ) ->
        if err
          msg.reply( hudson.errorToString err )
        else
          msg.reply( "Failed tests for #{data.jobName}" )
          for testcase in data.failedTests
            msg.reply( "#{testcase.url}" )
      )

    # TODO Remove this after initial tests
    # Example on how to resolve a groupchat message to a specific user message
    robot.respond /.*test ping me/i, ( msg ) ->
      envelope =
        room: xmppIdResolver.getRealJIDFromGroupchatJID msg.envelope.user.jid
        user:
          type: 'chat'
      robot.send( envelope, "Ping from #{robot.name}" )

    #
    #
    # Actual implementation
    #
    #

    #
    # Setup "routes":
    #

    #TODO Implement regex for: Broadcast failed tests for project {} to room {}
    # Tell Hubot to broadcast test results to the specified room.
    robot.respond /Broadcast failed tests for project {} to room {}/i, ( msg ) ->
      console.log "Not implemented"

    #TODO Implement regex for: Stop broadcasting failed tests for project {} to room {} 
    # Tell Hubot to stop broadcast test results to the specified room.
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # Monitor tests for the specified build which is part of specified project.
    #TODO Implement regex for: Watch failed tests for project {} using build {} 
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # Stop monitoring tests for the specified build which is part of specified project.
    #TODO Implement regex for: Stop watching failed tests of build {} for project {}
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # For security reason, must be sent in groupchat
    #TODO Implement regex for: Set manager for project {} to {} 
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # Configure warning or escalade threshold. Accepted only if from project manager
    #TODO Implement regex for: Set {warning|escalade} test fix delay for project {} to {} {hour|day}(s) 
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # Assign a test/range/list of tests to a user
    #TODO Implement regex for: Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser} 
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    # Display failed test and assignee
    #TODO Implement regex for: Show test report for project {} 
    robot.respond /.*/i, ( msg ) ->
      console.log "Not implemented"

    #TODO Implement regex for: Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser}
    robot.respond /.*Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser}/i, ( msg ) ->
      # TODO Check if it's a known user when message is from a groupchat. If unknown user, reply 'I don't know you #{username}, please send me 'Assign {requested_assignment} of project #{projectname} to me' in private'
      # TODO Reply private chat: xxx was assigned to you. Will remind in x hours
      # TODO Persist assignment
      console.log "Not implemented"

    # Setup watchdog
    setInterval( @.watchdog, 5 * 60 * 1000 )

  # Called when a new test result is available
  reportFailedTests: ( projectname, testResults ) ->
    # TODO Send the following to room:
    #   The following tests for project {} failed:
    #     1 - http...
    #     2 - http...


    # Notify which tests are not assigned. Can be used to send on demand, broadcast to room or escalade to manager
  notifyUnassignedTest: ( projectname, to_jid ) ->
    # TODO Update lastBroadcastId of unassigned tests in datastructure 
    # TODO Send to to_jid:
    # The following tests are still not assigned:
    #   1 - http...
    #   2 - http...

    # Notify of test fail past warning threshold
  notifyTestStillFail: ( projectname, to_jid ) ->
    # Failed tests for project {}:
    #- http://... is not assigned and fail since {failSinceDate}
    # or 
    #- http://... was assigned to {username | you} {x hours} ago

  watchdog: () ->
    # TODO Check for build status
    # TODO Check and notifyUnassignedTest() after env.HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES minutes
    # TODO Check and notifyTestStillFail() if testfail past warning or escalade threshold

    # to_jid = 'mdarveau@jabber.8d.com'
  sendPrivateMesssage: ( to_jid, message ) ->
    envelope =
      room: to_jid
      user:
        type: 'chat'
    robot.send( envelope, message )

  # to_jid = 'room@conference.hostname'
  sendGroupChatMesssage: ( to_jid, message ) ->
    # TODO Validate if this works
    envelope =
      room: to_jid
      user:
        type: 'groupchat'
    robot.send( envelope, message )

module.exports = ( robot ) ->
  new HudtonTestManager( robot )