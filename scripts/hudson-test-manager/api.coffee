# Most method accept a jsonCallback with signature (err, response as json object)

inspect = require( 'eyes' ).inspector( {maxLength: false} )

module.exports =
  authRequest: ( http, url ) ->
    req = http( url, {rejectUnauthorized: false} )
    req.auth( 'jobot', 'jobot' )

getJson: ( req, jsonCallback ) ->
  req.get() ( err, res, body ) ->
    jsonCallback( err ) if err
  
    try
      jsonBody = JSON.parse( body ) # inspect jsonBody
      jsonCallback null, jsonBody
  
    catch error
      jsonCallback( error )

# Get the build status for a specific job
getBuildStatus: ( jobName, http, jsonCallback ) ->
  req = @authRequest( http, "https://solic1.dev.8d.com:8443/job/#{jobName}/api/json" )
  @getJson req, (err, data) ->
    result = {}
    result.name = jsonBody.name
    