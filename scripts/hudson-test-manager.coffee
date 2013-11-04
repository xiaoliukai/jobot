# Description #   Monitor and dispatch build test failure on hudson # # Dependencies: #   none # # Configuration: #   none # # Commands: #   (...)test(...) - Make some noise #   hubot (...)test report(...) - Report failed builds # # Notes: #    # # Author: #   Manuel Darveau

inspect = require( 'eyes' ).inspector( {maxLength: false} )

HudsonConnection = require( './hudson-test-manager/hudson_connection.coffee' )
hudson = new HudsonConnection( 'https://solic1.dev.8d.com:8443' )

module.exports = ( robot ) ->
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