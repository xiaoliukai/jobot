inspect = require( 'eyes' ).inspector( {maxLength: false} )
HttpClient = require 'scoped-http-client'

# Mimic robot.http
http = ( url, options ) ->
  HttpClient.create( url, options ).header( 'User-Agent', "Hubot/#{@version}" )

authRequest = ( http, url ) ->
  req = http( url, {rejectUnauthorized: false} )
  req.auth( 'jobot', 'jobot' )

printJson = (path) ->
  req = authRequest( http, "https://solic1.dev.8d.com:8443/#{path}/api/json" )
  req.get() ( err, res, body ) ->
    inspect( err ) if err
  
    try
      inspect JSON.parse(body)
    catch error
      inspect( body )

#printJson 'job/ftk_trunk_test/lastCompletedBuild'
printJson 'job/ftk_trunk_test/lastCompletedBuild/testReport'