##
# Description
#   Monitor i18n key translation 
# 
# Dependencies:  
#   none  
#  
# Configuration: 
#   TODO  
#  
# Commands:
#   hubot TODO
#
# Author:  
#   Manuel Darveau 
#
fs = require 'fs'
Path = require 'path'
xpath = require 'xpath'
dom = require( 'xmldom' ).DOMParser
require( "natural-compare-lite" )

class I18nWatcher

  constructor: ( @robot ) ->
    @state = {}

    # Tell Hubot to broadcast test results to the specified room.
    robot.respond /Watch translations on git repo (\S*) branch (\S*)/i, ( msg ) =>
      @backend.checkForNewTestRun()

    start: () ->
      # Setup watchdog
      setInterval( @.loop, 1 * 60 * 1000 )

  loop: () =>
    # Check for new commits
    @checkForChanges()

  watchProject: ( project ) ->
    giturl = msg.match[1]
    branch = msg.match[2]
    @persist ( storage ) ->
      info =
        'giturl': giturl
        'branch': branch
        'workdir': Math.random().toString( 36 ).substring( 10 )
      storage.projects.push info
    msg.send( "Will watch translations of #{giturl} branch #{branch}" )

  checkForChanges: () ->
    console.log "Looking for untranslated keys..."
    storage = @readstorage()
    for info in storage.projects
      console.log "  for #{info.giturl} branch #{info.branch} in directory #{info.workdir}"


  getUntranslatedKeyInProject: ( project, callback ) ->
    fs.readFile Path.resolve( project, 'ftk-i18n/src/main/xliff/SolsticeConsoleStrings_en.xlf' ), ( err, data ) ->
      if err
        callback ( err )
        return
      dom = new dom().parseFromString( data.toString() )
      nodes = xpath.select( "//trans-unit[target='']/@id", dom )
      untranslatedKeys = []
      for id in nodes
        untranslatedKeys.push id.value
      untranslatedKeys.sort String.naturalCompare
      callback null, untranslatedKeys

  # Storage
  persist: ( callback ) ->
    storage = @robot.brain.get 'I18nWatcher'
    storage?={}
    storage.projects?= []
    callback( storage )
    @robot.brain.set 'I18nWatcher', storage
    @robot.brain.save()
  readstorage: () ->
    storage = @robot.brain.get 'I18nWatcher'
    storage?={}
    storage.projects?= []
    return storage


module.exports = ( robot ) ->
  new I18nWatcher( robot )

watcher = new I18nWatcher();
watcher.getUntranslatedKeyInProject '/Users/mdarveau/git_workspace/ftk', ( err, keys ) ->
  console.log err if err
  for key in keys
    console.log key