# Most method accept a jsonCallback with signature (err, response as json object)

inspect = require( 'eyes' ).inspector( {maxLength: false} )

class HudsonConnection

  constructor: ( hudson_url ) ->
    @hudson_url = hudson_url

  #
  #
  # Helper functions
  #
  #

  authRequest: ( http, url ) ->
    #req = http( url, {rejectUnauthorized: false} )
    req = http( url )
	# the password and the user for the service is now stored in a file called auth.json in the root directory
    fs = require 'fs'
    path = require 'path'
    try
        login = JSON.parse fs .readFileSync   path.resolve ".", "auth.json"
        req.auth( login.hudson.user, login.hudson.password )
    catch err
        console.log "There was an I/O error : #{err}"
        process.exit(1)
    return req

  getJson: ( req, jsonCallback, builder ) ->
    req.get() ( err, res, body ) ->
      jsonCallback( err ) if err

      if res.statusCode != 200
        jsonCallback( {req: req, res: res, body: body} )
      else
        try
        # Parse the json result
        #  console.log body
          jsonBody = JSON.parse( body )

          # Convert the response if needed
          jsonBody = builder jsonBody if builder

          # Callback
          jsonCallback null, jsonBody

        catch error
          jsonCallback( error )
    return

  errorToString: ( err ) ->
    if err.res
      if err.res.statusCode == 404
        return "Not found '#{err.res.req.path}'"
      else if err.res.statusCode != 200
        return "Unknown error (#{err.res.statusCode}): #{err.body}"
    else
      console.log inspect err
      return err

  #
  #
  # API
  #
  #

  # Get the build status for a specific job
  # .jobName: 'jobName'
  # .number: ####
  # .result: 'UNSTABLE', ...
  # .url: http://...
  # .culprits: [{fullName:}]
  getBuildStatus: ( jobName, http, jsonCallback ) ->
    req = @authRequest( http, "#{@hudson_url}/job/#{jobName}/lastCompletedBuild/api/json" )
    builder = ( res ) ->
      result = {}
      result.jobName = jobName
      result.number = res.number
      result.result = res.result
      result.url = res.url
      return result
    @getJson req, jsonCallback, builder
    return

  # Get the test report for a specific job
  # return:
  #   jobName: String the project or 'job' name
  #   failedTests: Map with key=testname, value=
  #     name: String of the test Class name
  #     url: The URL to the test report
  getTestReport: ( jobName, buildnumber, http, jsonCallback ) ->
    hudson_url = @hudson_url
    req = @authRequest( http, "#{@hudson_url}/job/#{jobName}/#{buildnumber}/testReport/api/json" )
    builder = ( res ) ->
      result = {}
      result.jobName = jobName

      # Get failed tests
      result.failedTests = {}
      for suite in res.suites
        for testcase in suite.cases
          if testcase.status == 'FAILED' or testcase.status == 'REGRESSION'
            # The package name is in a separate path element than test Class name
            lastDot = testcase.className.lastIndexOf( '.' )
            urlPath = testcase.className.substring( 0, lastDot ) + '/' + testcase.className.substring( lastDot + 1 )
            result.failedTests[testcase.className] =
              name: testcase.className
              url: "#{hudson_url}/job/#{jobName}/lastCompletedBuild/testReport/#{urlPath}"

      return result
    @getJson req, jsonCallback, builder
    return

module.exports = HudsonConnection