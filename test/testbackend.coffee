assert = require( 'assert' )

{User, Brain} = require 'hubot'

robot =
  name: 'bot' 
  logger:
    debug: () ->
    warning: () ->
  on: ( event ) ->

robot.brain = new Brain( robot )

@backend = require( '../scripts/hudson-test-manager/backend' )( robot )

@backend.broadcastTestToRoom "myproject", "myroom", ( err ) ->
  assert.ifError err

@backend.getProjects ( err, projects ) ->
  for project in projects
    console.log project
  assert projects["myproject"]
  
@backend.watchBuildForProject "mybuild1", "myproject", ( err ) ->
  assert.ifError err

@backend.watchBuildForProject "mybuild2", "myproject", ( err ) ->
  assert.ifError err

# Assert both builds are watched for project
@backend.getBuildsForProject "myproject", ( err, builds ) ->
  assert builds["mybuild1"]
  assert builds["mybuild2"]
  
@backend.stopWatchingBuildForProject "mybuild1", "myproject", ( err ) ->
  assert.ifError err
  
@backend.getBuildsForProject "myproject", ( err, builds ) ->
  assert builds["mybuild2"]

console.log "Success"