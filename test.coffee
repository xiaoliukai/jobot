inspect = require('eyes').inspector({maxLength: false})
HttpClient = require 'scoped-http-client'

# Mimic robot.http
http = ( url, options ) ->
  HttpClient.create( url, options ).header( 'User-Agent', "Hubot/#{@version}" )

api = require './scripts/hudson-test-manager/api'

api.getBuildStatus( 'ftk_trunk_test', http, ( err, res, body ) ->
  if err
    inspect err, 'Error'
    inspect body, 'Body'
  try
    inspect JSON.parse(body), 'Body'
  catch error
    console.log body
)