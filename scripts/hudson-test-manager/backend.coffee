{EventEmitter} = require 'events'

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
#       lastbuild: String build number
#     failedtests: key=testname, value=
#       builds: String[] where the test was seen failling
#       since: Date - firstFailDate
#       detail:
#         name: The test name
#         url: The test name
#       assigned: String - User assigned to test or undefined if none
#       assignedDate: Date - When the test was assigned
#
# Emits:
#  err: On error in the background treads. Pass a String that contains the error message
#

class HudsonTestManagerBackendSingleton extends EventEmitter

  instance = null

  @get: ( robot ) ->
    instance ?= new HudsonTestManagerBackend( robot )

  class HudsonTestManagerBackend

    constructor: ( robot, hudson ) ->
      @robot = robot
      @hudson = hudson

    # private
    persist: ( callback ) ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      callback( storage )
      @robot.brain.set 'HudsonTestManagerBackend', storage
      # console.log "Brain: " + util.inspect(@robot.brain.get 'HudsonTestManagerBackend')

    # private
    readstorage: ( ) ->
      storage = @robot.brain.get 'HudsonTestManagerBackend'
      storage?={}
      storage.projects?={}
      return storage

    #
    # public methods:
    #
      
    broadcastTestToRoom: ( project, room ) ->
      @persist ( storage ) ->
        storage.projects[project]?={}
        storage.projects[project].room = room

    getBroadcastRoomForProject: ( project ) ->
       @readstorage ( storage ) ->
        callback null, storage.projects[project]?.room
      
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
    getProjects: ( ) ->
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
    #   since: Date
    #   assigned: String
    #
    persistFailedTests: ( project, build, tests ) ->
      currentFailedTest = {}
      newFailedTest = {}
      fixedTests = {}
      @persist ( storage )->
        storage.projects[project]?={}
        previousFailedTest = storage.projects[project].failedtests

        # Copy current assignment if any
        for test, detail of tests
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
              since: new Date()
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

      return [fixedTests, newFailedTest, currentFailedTest ]

    #
    # Return all failed tests for project.
    # callback: err, failedTests, unassignedTests, assignedTests
    # All lists are map with key=testname and value is:
    #   test: Object passed in value of tests
    #   since: Date
    #   assigned: String
    #
    getFailedTests: ( project ) ->
      storage = @readstorage()
      assigned = {}
      unassigned = {}
      for testname, detail of storage.projects[project].failedtests
        unassigned[testname] = detail if not detail.assigned
        assigned[testname] = detail if detail.assigned
      return [storage.projects[project].failedtests, unassigned, assigned ]

    #
    # Assign the specified list of tests to the user
    # tests: Array of string representing test name
    #
    assignTests: ( project, testnames, user ) ->
      @persist ( storage )->
        for testname in testnames
          storage.projects[project]?.failedtests?[testname]?.assigned = user
          storage.projects[project]?.failedtests?[testname]?.assignedDate = new Date()

    #
    # Return all assigned tests for the user.
    # Return: object with projectname as key and value is object with definition:
    #  failedtests: Key is test name, value is object with definition
    #    since: Date of first test failure
    #    assigned: User assigned
    #    assignedDate: Date of assignment
    #  assignedDate: Date when was the test assigned 
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
