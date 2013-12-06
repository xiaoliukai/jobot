util = require( 'util' )

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
#     builds
#       ftk-master-test-bike
#         tests[com.eightd.ftk.some.test]
#           failSinceDate: firstFailDate
#           assignee: jfcroteau - Used assigned to test or undefined if none
#           assignDate: date - When the test was assigned
#         tests[com.eightd.some.other.test]
#           failSinceDate: firstFailDate
#           assignee: null
#   TODO: add history

class HudsonTestManagerBackendSingleton

  instance = null

  @get: ( robot ) ->
    instance ?= new HudsonTestManagerBackend( robot )

  class HudsonTestManagerBackend

    constructor: ( robot ) ->
      @robot = robot

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

    setThresholdForProject: ( project, level, amount, unit, callback ) ->
      unless unit not in ['hour', 'day']
        callback( "Unit must be 'hour' or 'day'. Got #{unit}" )
        return
      @persist ( storage )->
        amount *= 24 if unit is "day"

        storage.projects[project]?={}
        storage.projects[project].fix_delay?={}
        storage.projects[project].fix_delay[level] = amount
      callback( null )

    #
    # Store currently failling tests for a project.
    # Callback: err, fixedTests, newFailedTest, currentFailedTest
    # All lists are map with test name as key and value if an object defined as:
    #   since: Date
    #   assigned: String
    #
    persistFailedTests: ( project, tests, callback ) ->
      @persist ( storage )->
        storage.projects[project]?={}
        previousFailedTest = storage.projects[project].failedtests
        currentFailedTest = []
        newFailedTest = []

        # Copy current assignment if any
        for test in tests
          if previousFailedTest?[test]
            # Was already failling
            currentFailedTest[test] = previousFailedTest?[test]
            delete previousFailedTest?[test]
          else
            # New failed test
            currentFailedTest[test] =
              since: new Date()
            newFailedTest.push test

        # Only have fixed tests remaining
        fixedTests = previousFailedTest

        # Store current test fail
        storage.projects[project].failedtests = currentFailedTest
      callback( null, fixedTests, newFailedTest, currentFailedTest )

    #
    # Assign the specified list of tests to the user
    #
    assignTests: ( project, tests, user, callback ) ->
      for test in tests
        storage.projects[project]?.failedtests?[test]?.assigned = user
      callback( null )

module.exports = ( robot ) ->
  HudsonTestManagerBackendSingleton.get( robot )
