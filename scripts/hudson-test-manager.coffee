# Description #   Monitor and dispatch build test failure on hudson # # Dependencies: #   none # # Configuration: #   none # # Commands: #   (...)test(...) - Make some noise #   hubot (...)test report(...) - Report failed builds # # Notes: #    # # Author: #   Manuel Darveau

util = require('util')

HudsonConnection = require( './hudson-test-manager/hudson_connection' )
hudson = new HudsonConnection( 'https://solic1.dev.8d.com:8443' )

module.exports = ( robot ) ->
  
  XmppIdResolver = require( './xmpp-id-resolver' )( robot )
  
  robot.respond /.*status for (.*).*/i, ( msg ) ->
    jobName = msg.match[1]
    console.log "Build status requested for #{jobName}"
    hudson.getBuildStatus( jobName, robot.http, ( err, data ) ->
      msg.reply( hudson.errorToString err ) if err
      msg.reply( "#{jobName} (build #{data.number}) is #{data.result}. See #{data.url}" ) if !err )

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
  
  # Example on how to resolve a groupchat message to a specific user message
  robot.respond /.*test ping me/i, ( msg ) ->
    envelope =
      room: XmppIdResolver.getRealJIDFromGroupchatJID msg.envelope.user.jid
      user:
        type: 'chat'
    robot.send( envelope, "Ping from #{robot.name}" )
    
  watchdog = () ->
    console.log "Timer triggered"
    envelope =
      room: 'mdarveau@jabber.8d.com'
      user:
        type: 'chat'
    
    robot.send( envelope, "Test" )
    
  #setInterval( watchdog, 1000 ) 