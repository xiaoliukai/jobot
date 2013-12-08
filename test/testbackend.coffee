assert = require( 'assert' )
util = require( 'util' )

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
  assert.ifError err
  for project in projects
    console.log project
  assert projects["myproject"]

@backend.watchBuildForProject "mybuild1", "myproject", ( err ) ->
  assert.ifError err

@backend.watchBuildForProject "mybuild2", "myproject", ( err ) ->
  assert.ifError err

# Assert both builds are watched for project
@backend.getBuildsForProject "myproject", ( err, builds ) ->
  assert.ifError err
  assert builds["mybuild1"]
  assert builds["mybuild2"]

@backend.stopWatchingBuildForProject "mybuild1", "myproject", ( err ) ->
  assert.ifError err

@backend.getBuildsForProject "myproject", ( err, builds ) ->
  assert.ifError err
  assert builds["mybuild2"]

@backend.setManagerForProject "myuser", "myproject", ( err ) ->
  assert.ifError err

@backend.getManagerForProject "myproject", ( err, manager ) ->
  assert.ifError err
  assert.strictEqual manager, "myuser"

@backend.setThresholdForProject "myproject", "warning", "2", "years", ( err ) ->
  assert err

@backend.setThresholdForProject "myproject", "warning", "2", "day", ( err ) ->
  assert.ifError err

@backend.getThresholdForProject "myproject", "warning", ( err, threshold ) ->
  assert.ifError err
  assert.strictEqual threshold, 48

@backend.persistFailedTests "myproject", [ 'com.test1', 'com.test2' ], ( err, fixedTests, newFailedTest, currentFailedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( fixedTests ).length, 0
  assert.strictEqual Object.keys( newFailedTest ).length, 2
  assert.strictEqual Object.keys( currentFailedTest ).length, 2

# No changes
@backend.persistFailedTests "myproject", [ 'com.test1', 'com.test2' ], ( err, fixedTests, newFailedTest, currentFailedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( fixedTests ).length, 0
  assert.strictEqual Object.keys( newFailedTest ).length, 0
  assert.strictEqual Object.keys( currentFailedTest ).length, 2

# New failed test
@backend.persistFailedTests "myproject", [ 'com.test1', 'com.test2', 'com.test3' ], ( err, fixedTests, newFailedTest, currentFailedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( fixedTests ).length, 0
  assert.strictEqual Object.keys( newFailedTest ).length, 1
  assert newFailedTest['com.test3']
  assert.strictEqual Object.keys( currentFailedTest ).length, 3

# 1 fixed
@backend.persistFailedTests "myproject", [ 'com.test2', 'com.test3' ], ( err, fixedTests, newFailedTest, currentFailedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( fixedTests ).length, 1
  assert fixedTests['com.test1']
  assert.strictEqual Object.keys( newFailedTest ).length, 0
  assert.strictEqual Object.keys( currentFailedTest ).length, 2

# 1 new, 1 fixed
@backend.persistFailedTests "myproject", [ 'com.test3', 'com.test4' ], ( err, fixedTests, newFailedTest, currentFailedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( fixedTests ).length, 1
  assert fixedTests['com.test2']
  assert.strictEqual Object.keys( newFailedTest ).length, 1
  assert newFailedTest['com.test4']
  assert.strictEqual Object.keys( currentFailedTest ).length, 2

@backend.getFailedTests "myproject", ( err, failedTest ) ->
  assert.ifError err
  assert.strictEqual Object.keys( failedTest ).length, 2
  assert failedTest['com.test3']
  assert failedTest['com.test4']

@backend.assignTests "myproject", [ 'com.test3' ], "myuser", ( err, failedTest ) ->
  assert.ifError err

@backend.getFailedTests "myproject", ( err, failedTest ) ->
  assert.ifError err
  assert.strictEqual failedTest['com.test3'].assigned, "myuser"

@backend.getAssignedTests "myuser", ( err, assignedTests ) ->
  assert.ifError err
  assert.strictEqual Object.keys( assignedTests ).length, 1
  assert.strictEqual Object.keys( assignedTests["myproject"].failedtests ).length, 1
  assert assignedTests["myproject"].failedtests['com.test3']
  assert.strictEqual assignedTests["myproject"].failedtests['com.test3'].assigned, "myuser"

console.log "Success"