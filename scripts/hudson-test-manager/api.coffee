inspect = require('eyes').inspector({maxLength: false})

module.exports =
  authRequest: ( http, url ) ->
    req = http( url )
    req.auth( 'mdarveau', 'password' )

  getBuildStatus: ( http, callback ) ->
    req = @authRequest( http, "https://solic1.dev.8d.com:8443/view/ftk-tests/api/json" )
    req.get() callback
      