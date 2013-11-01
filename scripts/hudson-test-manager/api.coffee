inspect = require( 'eyes' ).inspector( {maxLength: false} )

module.exports =
  authRequest: ( http, url ) ->
    req = http( url, {rejectUnauthorized: false} )
    req.auth( 'jobot', 'jobot' )

  getBuildStatus: ( jobName, http, callback ) ->
    req = @authRequest( http, "https://solic1.dev.8d.com:8443/job/#{jobName}/api/json" )
    req.get() ( err, res, body ) ->
      callback( err ) if err

      try
        jsonBody = JSON.parse( body )
        # inspect jsonBody
        
        result = {}
        result.name = jsonBody.name
        
      catch error
        callback( error, res, body )