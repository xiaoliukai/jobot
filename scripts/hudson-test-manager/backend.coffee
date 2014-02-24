{EventEmitter} = require 'events'
moment = require 'moment'

util = require 'util'

HudsonConnection = require './hudson_connection'

# Datastructure in brain:
# HudsonTestManagerBackend
#   projects[projectname]
#     room: backoffice
#     manager: mdarveau@jabber.8d.com
#     fix_delay[warning]: 24h
#     fix_delay[escalade]: 24h
#     builds: key=jobname, value=
#       lastbuildnumber: String build number
#     failedtests: key=testname, value=
#       builds: String[] where the test was seen failling
#       since: moment - firstFailDate
#       detail:
#         name: The test name
#         url: The test name
#       assigned: String - User assigned to test or undefined if none
#       assignedDate: moment - When the test was assigned
#
# Emits:
#  err: On error in the background treads. Pass a String that contains the error message
#  testresult: projectname, buildname, fixedTests, newFailedTest, currentFailedTest. All tests list are map with key=testname and value is:
#   test: Object passed in value of tests
#   since: moment
#   assigned: String
#  buildfailed: project, buildname, url
#

class HudsonTestManagerBackendSingleton

  instance = null

  @get: ( robot, hudson ) ->
    instance ?= new HudsonTestManagerBackend( robot, hudson )

  class HudsonTestManagerBackend extends EventEmitter

    constructor: ( robot, hudson ) ->
      @robot = robot
      @hudson = hudson

    start: () ->
      # Setup watchdog
      setInterval( @.loop, 1 * 60 * 1000 )

    # private
    persist: ( callback ) ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      callback( storage )
      @robot.brain.set 'HudsonTestManagerBackend', storage
      @robot.brain.save()
    # console.log "Brain: " + util.inspect(@robot.brain.get 'HudsonTestManagerBackend')

    # private
    readstorage: () ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      return storage

    loop: () =>
      # Check for new builds
      @checkForNewTestRun()

    # TODO Check and notifyUnassignedTest() after env.HUDSON_TEST_MANAGER_ASSIGNMENT_TIMEOUT_IN_MINUTES minutes
    # TODO Check and notifyTestStillFail() if testfail past warning or escalade threshold

    checkForNewTestRun: () ->
      console.log "Checking builds..."
      storage = @readstorage()
      for projectname of storage.projects
        do (projectname) =>
          console.log "  for project #{projectname}"
          for buildname, lastbuilddetail of storage.projects[projectname]?.builds
            do ( buildname, lastbuilddetail ) =>
              console.log "    for buildname #{buildname}"
              @hudson.getBuildStatus buildname, @robot.http, ( err, buildresult ) =>
                if err
                  console.log err
                else
                  @parseBuildResult projectname, buildname, lastbuilddetail, buildresult

    parseBuildResult: ( projectname, buildname, lastbuilddetail, buildresult ) ->
      # Check if we have a new build and persist if not
      unless buildresult.number != lastbuilddetail.lastbuildnumber
        console.log "Last build of #{projectname}/#{buildname} is still #{buildresult.number}"
        return

      console.log "Status of #{projectname}/#{buildname} is #{buildresult.result}"
      switch buildresult.result
        when 'UNSTABLE'
          @parseTestRunOfProject projectname, buildname
        when 'SUCCESS'
        # Call @persistFailedTests without failed tests
          [fixedTests, newFailedTest, currentFailedTest] = @persistFailedTests projectname, buildname, {}
          @emit 'testresult', projectname, buildname, fixedTests, newFailedTest, currentFailedTest
        when 'FAILURE'
          @emit 'buildfailed', projectname, buildname, buildresult.url

      @persistBuildNumber projectname, buildname, buildresult.number

    #
    # Persist the last build number processed
    #
    persistBuildNumber: ( projectname, buildname, buildnumber ) ->
      @persist ( storage ) ->
        console.log "Persisting last build of #{projectname}/#{buildname} to #{buildnumber}"
        storage.projects[projectname].builds[buildname].lastbuildnumber = buildnumber

    #
    # Parse test results
    #
    parseTestRunOfProject: ( projectname, buildname ) ->
      console.log "Parsing test report for #{projectname}/#{buildname}"
      @hudson.getTestReport buildname, @robot.http, ( err, data ) =>
        if err
          @emit 'err', @hudson.errorToString err
        else
          [fixedTests, newFailedTest, currentFailedTest] = @persistFailedTests projectname, buildname, data.failedTests
          @emit 'testresult', projectname, buildname, fixedTests, newFailedTest, currentFailedTest

    #
    # public methods:
    #

    broadcastTestToRoom: ( project, room ) ->
      @persist ( storage ) ->
        storage.projects[project]?={}
        storage.projects[project].room = room

    getBroadcastRoomForProject: ( project ) ->
      @readstorage().projects[project]?.room

    watchBuildForProject: ( build, project ) ->
      @persist ( storage ) ->
        storage.projects[project]?={}
        storage.projects[project].builds?={}
        storage.projects[project].builds[build]?={}

    stopWatchingBuildForProject: ( build, project ) ->
      @persist ( storage ) ->
        storage.projects[project]?={}
        storage.projects[project].builds?={}
        delete storage.projects[project].builds[build]

    #
    # Return a map with project name as key
    #
    getProjects: () ->
      @readstorage().projects

    #
    # Return a map with build name as key
    #
    getBuildsForProject: ( project ) ->
      @readstorage().projects[project].builds

    setManagerForProject: ( manager, project ) ->
      @persist ( storage ) ->
        storage.projects[project]?={}
        storage.projects[project].manager = manager

    getManagerForProject: ( project ) ->
      @readstorage().projects[project]?.manager

    setThresholdForProject: ( project, level, amount, unit ) ->
      throw "Level must be 'warning' or 'escalade'. Got '#{level}'" unless level in [ 'warning', 'escalade' ]
      throw "Unit must be 'hour' or 'day'. Got '#{unit}'" unless unit in [ 'hour', 'day' ]

      @persist ( storage )->
        amount *= 24 if unit is "day"
        storage.projects[project]?={}
        storage.projects[project].fix_delay?={}
        storage.projects[project].fix_delay[level] = amount

    #
    # Return the threshold for the specified level in hours
    #
    getThresholdForProject: ( project, level ) ->
      @readstorage().projects[project]?.fix_delay?[level]
      
    #
    # Store currently failling tests for a project.
    # tests: Map with key=testname, value={name:, url:}
    # Callback: err, fixedTests, newFailedTest, currentFailedTest
    # All lists are map with key=testname and value is:
    #   test: Object passed in value of tests
    #   since: moment
    #   assigned: String
    #
    persistFailedTests: ( project, build, failedtests ) ->
      currentFailedTest = {}
      newFailedTest = {}
      fixedTests = {}
      @persist ( storage )->
        storage.projects[project]?={}
        previousFailedTest = storage.projects[project].failedtests

        # Copy current assignment if any
        for test, detail of failedtests
          if previousFailedTest?[test]
            #console.log "#{test} failed previously"
            # Was already failling
            currentFailedTest[test] = previousFailedTest?[test]
            delete previousFailedTest?[test]
          else
            #console.log "#{test} new fail"
            # New failed test
            currentFailedTest[test] =
              name: detail.name
              url: detail.url
              since: moment()
              builds: {}
            newFailedTest[test] = currentFailedTest[test]

          # Make sure this build is in the list of build that have seen it fail
          currentFailedTest[test].builds[build] = true

        # Copy remaining tests as fixed tests
        for test, state of previousFailedTest
          # Fixed only if it was seen failling on that build
          if state.builds[build]
            fixedTests[test] = state
          else
            currentFailedTest[test] = previousFailedTest?[test]

        # Store current test fail
        storage.projects[project].failedtests = currentFailedTest
        
      return [ fixedTests, newFailedTest, currentFailedTest ]

    #
    # Return all failed tests for project.
    # callback: err, failedTests, unassignedTests, assignedTests
    # All lists are map with key=testname and value is:
    #   test: Object passed in value of tests
    #   since: moment
    #   assigned: String
    #
    getFailedTests: ( project ) ->
      storage = @readstorage()
      failedtests = storage.projects[project].failedtests
      assigned = {}
      unassigned = {}
      for testname, detail of storage.projects[project].failedtests
        unassigned[testname] = detail if not detail.assigned
        assigned[testname] = detail if detail.assigned
        
      return [ failedtests, unassigned, assigned ]

    #
    # Assign the specified list of tests to the user
    # tests: Array of string representing test name
    #
    assignTests: ( project, testnames, user ) ->
      @persist ( storage )->
        for testname in testnames
          # Check if testname exists and if not, throw exception
          throw "Unknown test '#{testname}" unless storage.projects[project]?.failedtests?[testname]
          storage.projects[project]?.failedtests?[testname]?.assigned = user
          storage.projects[project]?.failedtests?[testname]?.assignedDate = moment()

    #
    # Return all assigned tests for the user.
    # Return: object with projectname as key and value is object with definition:
    #  failedtests: Key is test name, value is object with definition
    #    since: moment of first test failure
    #    assigned: User assigned
    #    assignedDate: moment of assignment
    #  assignedDate: moment when was the test assigned 
    #
    getAssignedTests: ( user ) ->
      assignedtests = {}
      storage = @readstorage();
      for projectname, project of storage.projects
        for testname, detail of project.failedtests
          if detail.assigned is user
            assignedtests[projectname]?={}
            assignedtests[projectname].failedtests?={}
            assignedtests[projectname].failedtests[testname] =
              test: detail.test
              since: detail.since
              assigned: detail.assigned
              assignedDate: detail.assignedDate
      return assignedtests

module.exports = ( robot, hudson ) ->
  HudsonTestManagerBackendSingleton.get( robot, hudson )
