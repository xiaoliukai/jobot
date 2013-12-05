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
      callback( storage )
      @robot.brain.set 'HudsonTestManagerBackend', storage

    broadcastTestToRoom: ( project, room, callback ) ->
      @persist ( storage )->
        storage[project]?={}
        storage[project].room = room
        callback( null )

    watchBuildForProject: ( build, project, callback ) ->
      @persist ( storage )->
        storage[project]?={}
        storage[project].builds?={}
        storage[project].builds[build]?={}
        callback( null )

    stopWatchingBuildForProject: ( build, project, callback ) ->
      @persist ( storage )->
        storage[project]?={}
        storage[project].builds?={}
        delete storage[project].builds[build]
        callback( null )

    setManagerForProject: ( manager, project, callback ) ->
      @persist ( storage )->
        storage[project]?={}
        storage[project].manager = manager
        callback( null )

    setThresholdForProject: ( project, level, amount, unit, callback ) ->
      unless unit not in ['hour', 'day']
        callback( "Unit must be 'hour' or 'day'. Got #{unit}" )
        return
      @persist ( storage )->
        amount *= 24 if unit is "day"

        storage[project]?={}
        storage[project].fix_delay?={}
        storage[project].fix_delay[level] = amount
        callback( null )

    assignTests: ( project, tests, user, callback ) ->
      callback( null )

module.exports = ( robot ) ->
  HudsonTestManagerBackendSingleton.get( robot )
