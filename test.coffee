inspect = require('eyes').inspector({maxLength: false})
HttpClient = require 'scoped-http-client'

# Mimic robot.http
http = ( url ) ->
  HttpClient.create( url ).header( 'User-Agent', "Hubot/#{@version}" )

api = require './scripts/hudson-test-manager/api.coffee'

api.getBuildStatus( http, ( err, res, body ) ->
  inspect err, 'Error'
  inspect JSON.parse(body), 'Body'
)