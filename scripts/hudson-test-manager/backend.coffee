{EventEmitter} = require 'events'

util = require( 'util' )

HudsonConnection = require( 'hudson_connection' )

# Datastructure in brain:
# HudsonTestManagerBackend
#   projectname: (ie: 'ftk-master')
#     room: backoffice
#     lastBroadcastDate: date
#     lastBroadcastTests[]: Id used in last broadcast to room. Reset each time a broadcast to room is made
#     lastBroadcastTests[0]: com.eightd.ftk.some.test
#     lastBroadcastTests[1]: com.eightd.ftk.some.other.test
#     manager: mdarveau@jabber.8d.com
#     fix-delay
#       warning: 24h
#       escalade: 96h
#     builds: key=jobname, value=
#       lastbuild: String build number
#       tests: key=testname, value=
#         failSinceDate: firstFailDate
#         assignee: jfcroteau - Used assigned to test or undefined if none
#         assignDate: date - When the test was assigned
#   TODO: add history
#
# Emits:
#  err: On error in the background treads. Pass a String that contains the error message
#
#
#

class HudsonTestManagerBackendSingleton extends EventEmitter

  instance = null

  @get: ( robot ) ->
    instance ?= new HudsonTestManagerBackend( robot )

  class HudsonTestManagerBackend

    constructor: ( robot, hudson ) ->
      @robot = robot
      @hudson = hudson

    persist: ( callback ) ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      callback( storage )
      @robot.brain.set 'HudsonTestManagerBackend', storage
    # console.log "Brain: " + util.inspect(@robot.brain.get 'HudsonTestManagerBackend')

    readstorage: ( callback ) ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      callback( storage )

    broadcastTestToRoom: ( project, room, callback ) ->
      @persist ( storage )->
        storage.projects[project]?={}
        storage.projects[project].room = room
      callback( null )

    watchBuildForProject: ( build, project, callback ) ->
      @persist ( storage )->
        storage.projects[project]?={}
        storage.projects[project].builds?={}
        storage.projects[project].builds[build]?={}
      callback( null )

    stopWatchingBuildForProject: ( build, project, callback ) ->
      @persist ( storage )->
        storage.projects[project]?={}
        storage.projects[project].builds?={}
        delete storage.projects[project].builds[build]
      callback( null )

    #
    # Return a map with project name as key
    #
    getProjects: ( callback ) ->
      @readstorage ( storage ) ->
        callback null, storage.projects

    #
    # Return a map with build name as key
    #
    getBuildsForProject: ( project, callback ) ->
      @readstorage ( storage ) ->
        callback null, storage.projects[project].builds

    setManagerForProject: ( manager, project, callback ) ->
      @persist ( storage )->
        storage.projects[project]?={}
        storage.projects[project].manager = manager
      callback( null )

    getManagerForProject: ( project, callback ) ->
      @readstorage ( storage )->
        storage.projects[project]?={}
        callback null, storage.projects[project]?.manager

    setThresholdForProject: ( project, level, amount, unit, callback ) ->
      unless unit in [ 'hour', 'day' ]
        callback( "Unit must be 'hour' or 'day'. Got '#{unit}'" )
        return
      @persist ( storage )->
        amount *= 24 if unit is "day"

        storage.projects[project]?={}
        storage.projects[project].fix_delay?={}
        storage.projects[project].fix_delay[level] = amount
      callback( null )

    #
    # Return the threshold for the specified level in hours
    #
    getThresholdForProject: ( project, level, callback ) ->
      @readstorage ( storage )->
        storage.projects[project]?={}
        callback null, storage.projects[project]?.fix_delay?[level]

    #
    # Store currently failling tests for a project.
    # tests: Map with key=testname, value=detail
    # Callback: err, fixedTests, newFailedTest, currentFailedTest
    # All lists are map with key=testname and value is:
    #   test: Object passed in value of tests
    #   since: Date
    #   assigned: String
    #
    persistFailedTests: ( project, tests, callback ) ->
      currentFailedTest = {}
      newFailedTest = {}
      fixedTests = {}
      @persist ( storage )->
        storage.projects[project]?={}
        previousFailedTest = storage.projects[project].failedtests

        # Copy current assignment if any
        for test, detail of tests
          if previousFailedTest?[test]
            # Was already failling
            currentFailedTest[test] = previousFailedTest?[test]
            delete previousFailedTest?[test]
          else
            # New failed test
            currentFailedTest[test] =
              since: new Date()
              test: detail
            newFailedTest[test] = currentFailedTest[test]

        # Copy remaining tests as fixed tests
        for test, state of previousFailedTest
          fixedTests[test] = state

        # Store current test fail
        storage.projects[project].failedtests = currentFailedTest

      callback( null, fixedTests, newFailedTest, currentFailedTest )

    #
    # Return all failed tests for project.
    # callback: err, failedTests, unassignedTests, assignedTests
    # All lists are map with key=testname and value is:
    #   test: Object passed in value of tests
    #   since: Date
    #   assigned: String
    #
    getFailedTests: ( project, callback ) ->
      @readstorage ( storage ) ->
        assigned = {}
        unassigned = {}
        for testname, detail of storage.projects[project].failedtests
          unassigned[testname] = detail if not detail.assigned
          assigned[testname] = detail if detail.assigned
        callback null, storage.projects[project].failedtests, unassigned, assigned

    #
    # Assign the specified list of tests to the user
    # tests: Array of string representing test name
    #
    assignTests: ( project, testnames, user, callback ) ->
      @persist ( storage )->
        for testname in testnames
          storage.projects[project]?.failedtests?[testname]?.assigned = user
          storage.projects[project]?.failedtests?[testname]?.assignedDate = new Date()
      callback( null )

    #
    # Return all assigned tests for the user.
    # Return: object with projectname as key and value is object with definition:
    #  failedtests: Key is test name, value is object with definition
    #    since: Date of first test failure
    #    assigned: User assigned
    #    assignedDate: Date of assignment
    #  assignedDate: Date when was the test assigned 
    #
    getAssignedTests: ( user, callback ) ->
      assignedtests = {}
      @readstorage ( storage ) ->
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

      callback null, assignedtests

    #checkForNewTestRun: () ->
    #  @readstorage ( storage ) ->
    #    for projectname of storage
    #      for buildname of storage[projectname].builds
    #        @hudson.getBuildStatus buildname, @robot.http, ( err, build ) =>
    #          if build.result is 'UNSTABLE' && build.number != storage[projectname].builds[buildname].lastbuild
    #            @checkForNewBuildOfProject projectname, ( err, newBuild ) ->
    #              @checkForNewTestRunOfProject projectname
    #
    #checkForNewBuildOfProject: ( projectname, callback ) ->
    #
    #
    #checkForNewTestRunOfProject: ( projectname, jobname ) ->
    #  console.log "Checking tests report for #{jobname} in scope of project #{projectname}"
    #  @hudson.getTestReport jobname, @robot.http, ( err, data ) =>
    #    if err
    #      @emit 'err', hudson.errorToString err
    #    else
    #      @persistFailedTests projectname, data.failedTests, ( err, fixedTests, newFailedTest, currentFailedTest ) =>
    #        if err
    #          @emit 'err', err
    #        else
    #          @emit 'testresult', fixedTests, newFailedTest, currentFailedTest

module.exports = ( robot ) ->
HudsonTestManagerBackendSingleton.get( robot )
