# Most method accept a jsonCallback with signature (err, response as json object)

inspect = require( 'eyes' ).inspector( {maxLength: false} )

class TeamcityConnection

  constructor: ( teamcity_url ) ->
    @teamcity_url = teamcity_url

  #
  #
  # Helper functions
  #
  #

  authRequest: ( http, url ) ->
    fs = require 'fs'
    path = require 'path'
    try
        
        login = JSON.parse fs.readFileSync path.resolve ".", "auth.json"
    #req = http( url, {rejectUnauthorized: false} )
        req = http( url )
        req.auth( login.teamcity.user, login.teamcity.password)
        req.header( 'Accept', 'application/json' )
    #console.log JSON.stringify req, null, 4
    catch err
        console.log "There was an error : #{err}"
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
    # FIXED see ForProject Document that when a specific project should be used, the branch should be "$branch_name,project:$project_name
    req = @authRequest( http, "#{@teamcity_url}/httpAuth/app/rest/builds/?locator=branch:#{jobName},running:false,count:1" )
    #console.log JSON.stringify req, null , 4 
    builder = ( res ) ->
     # console.log "res :\n " + JSON.stringify res,null, 4
      result = {}
      result.jobName = jobName
      result.number = res.build[0].id
      # Convert to a common enum
      result.result = 'SUCCESS' if res.build[0].status == 'SUCCESS'
      result.result = 'UNSTABLE' if res.build[0].status == 'FAILURE'
      result.result = 'FAILURE' if res.build[0].status == 'ERROR'
      result.url = res.build[0].webUrl + '&tab=testsInfo'
      console.log "Result : "+JSON.stringify result, null,'\t'
      return result
    @getJson req, jsonCallback, builder
    return

  getBuildStatusForProject: (projectName, jobName, http, jsonCallback ) ->
    # FIXED Document that when a specific project should be used, the branch should be "$branch_name,project:$project_name
    req = @authRequest( http, "#{@teamcity_url}/httpAuth/app/rest/builds/?locator=branch:#{jobName},project:#{projectName},running:false,count:1" )
    #console.log JSON.stringify req, null , 4 
    builder = ( res ) ->
     # console.log "res :\n " + JSON.stringify res,null, 4
      result = {}
      result.jobName = jobName
      result.projectName = projectName
      result.number = res.build[0].id
      # Convert to a common enum
      result.result = 'SUCCESS' if res.build[0].status == 'SUCCESS'
      result.result = 'UNSTABLE' if res.build[0].status == 'FAILURE'
      result.result = 'FAILURE' if res.build[0].status == 'ERROR'
      result.url = res.build[0].webUrl + '&tab=testsInfo'
      console.log "Result : "+JSON.stringify result, null,'\t'
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
    teamcity_url = @teamcity_url
    req = @authRequest( http, "#{@teamcity_url}/httpAuth/app/rest/testOccurrences?locator=build:#{buildnumber},count:9999,status:FAILURE" )
    #console.log "HELLO WORLD"
    builder = ( res ) ->
      result = {}
      result.jobName = jobName

      # Get failed tests
      result.failedTests = {}
      for testcase in res.testOccurrence
          console.log JSON.stringify res, null, 4
        if testcase.status == 'FAILURE'
          className = testcase.name.substring( 0, testcase.name.lastIndexOf( '.' ) )
          result.failedTests[className] =
            name: className
            url: "#{teamcity_url}/viewLog.html?buildId=#{buildnumber}&tab=buildResultsDiv"
        
        console.log "Failed test : " + result.failedTests
            
            
      return result
    @getJson req, jsonCallback, builder
    return
    




module.exports = TeamcityConnection