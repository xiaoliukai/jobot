# Description
#   Monitor and dispatch build test failure on hudson
#
# Dependencies:
#   none
#
# Configuration:
#   none
#
# Commands:
#   (...)test(...) - Make some noise
#   hubot (...)test report(...) - Report failed builds
#
# Notes:
#   
#
# Author:
#   Manuel Darveau

api = require('./hudson-test-manager/api.coffee')

module.exports = ( robot ) ->

  robot.respond /.*test report.*/i, ( msg ) ->
    robot.http( "https://solic1.dev.8d.com:8443/view/ftk-tests/api/json" ).get( api ) ( err, res, body ) ->
      console.log(res)
      console.log(body)