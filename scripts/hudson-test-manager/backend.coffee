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
    # tests: Array of string representing test name
    # Callback: err, fixedTests, newFailedTest, currentFailedTest
    # All lists are objects with test name as key and value if an object defined as:
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
        for test in tests
          if previousFailedTest?[test]
            # Was already failling
            currentFailedTest[test] = previousFailedTest?[test]
            delete previousFailedTest?[test]
          else
            # New failed test
            currentFailedTest[test] =
              since: new Date()
            newFailedTest[test] = currentFailedTest[test]

        # Copy remaining tests as fixed tests
        for test, state of previousFailedTest
          fixedTests[test] = state
            
        # Store current test fail
        storage.projects[project].failedtests = currentFailedTest
        
      callback( null, fixedTests, newFailedTest, currentFailedTest )

    getFailedTests: ( project, callback ) ->
      @readstorage ( storage ) ->
        assigned = {}
        unassigned = {}
        for test, state of storage.projects[project].failedtests
          unassigned[test] = state if not state.assigned
          assigned[test] = state if state.assigned
        callback null, storage.projects[project].failedtests, unassigned, assigned

    #
    # Assign the specified list of tests to the user
    # tests: Array of string representing test name
    #
    assignTests: ( project, tests, user, callback ) ->
      @persist ( storage )->
        for test in tests
          storage.projects[project]?.failedtests?[test]?.assigned = user
          storage.projects[project]?.failedtests?[test]?.assignedDate = new Date()
      callback( null )

    #
    # Return all assigned tests for the user.
    # Return: object with projectname as key and value is object with definition:
    #  project: String project name
    #  test: String test name
    #  assignedDate: Date when was the test assigned 
    #
    getAssignedTests: ( user, callback ) ->
      # TODO
      
module.exports = ( robot ) ->
  HudsonTestManagerBackendSingleton.get( robot )
