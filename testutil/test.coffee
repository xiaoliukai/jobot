inspect = require('eyes').inspector({maxLength: false})
HttpClient = require 'scoped-http-client'

# Mimic robot.http
http = ( url, options ) ->
  HttpClient.create( url, options ).header( 'User-Agent', "Hubot/#{@version}" )

HudsonConnection = require('./../scripts/hudson-test-manager/hudson_connection')
hudson = new HudsonConnection( 'https://solic1.dev.8d.com:8443' )

hudson.getTestReport('ftk_bike_master_test', http, (err, data) ->
  #inspect err
  #inspect data
  if err
    console.log hudson.errorToString(err)
  else
    console.log("Failed tests for #{data.jobName}")
    for testcase in data.failedTests
      console.log("#{testcase.className}")
)