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

# Utility method to wrap an array of test name to the test object structure accepted by persistFailedTests
toHudsonTests = ( tests ) ->
  hudsonTests = {}
  for test in tests
    hudsonTests[test] =
      name: test
      url: "https://#{test}"
  return hudsonTests

@backend = require( '../scripts/hudson-test-manager/backend' )( robot )

# Bind a project to a room
@backend.broadcastTestToRoom "myproject", "myroom"
projects = @backend.getProjects()
assert projects["myproject"]

# Assert two builds can be watched for a project
@backend.watchBuildForProject "mybuild1", "myproject"
@backend.watchBuildForProject "mybuild2", "myproject"
builds = @backend.getBuildsForProject "myproject"
assert builds["mybuild1"]
assert builds["mybuild2"]

@backend.stopWatchingBuildForProject "mybuild1", "myproject"
builds = @backend.getBuildsForProject "myproject"
assert builds["mybuild2"]

@backend.setManagerForProject "myuser", "myproject"
manager = @backend.getManagerForProject "myproject"
assert.strictEqual manager, "myuser"

# Assert thresholds
try
  # Years is invalid
  @backend.setThresholdForProject "myproject", "warning", "2", "years"
catch err
  assert err

@backend.setThresholdForProject "myproject", "warning", "2", "day"
threshold = @backend.getThresholdForProject "myproject", "warning"
assert.strictEqual threshold, 48


[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test1', 'mybuild.test2' ] )
assert.strictEqual Object.keys( fixedTests ).length, 0
assert.strictEqual Object.keys( newFailedTest ).length, 2
assert.strictEqual Object.keys( currentFailedTest ).length, 2

# No changes
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test1', 'mybuild.test2' ] )
assert.strictEqual Object.keys( fixedTests ).length, 0
assert.strictEqual Object.keys( newFailedTest ).length, 0
assert.strictEqual Object.keys( currentFailedTest ).length, 2

# Failed test on another build
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild2", toHudsonTests( [ 'mybuild.test1', 'com.mybuild2.test1', 'com.mybuild2.test2' ] )
assert.strictEqual Object.keys( fixedTests ).length, 0
assert.strictEqual Object.keys( newFailedTest ).length, 2
assert.strictEqual Object.keys( currentFailedTest ).length, 4
assert.strictEqual Object.keys( currentFailedTest['mybuild.test1'].builds ).length, 2

# No changes
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test1', 'mybuild.test2' ] )
assert.strictEqual Object.keys( fixedTests ).length, 0
assert.strictEqual Object.keys( newFailedTest ).length, 0
assert.strictEqual Object.keys( currentFailedTest ).length, 4

# Fixed on build 2
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild2", toHudsonTests( [] )
assert.strictEqual Object.keys( fixedTests ).length, 3
assert.strictEqual Object.keys( newFailedTest ).length, 0
assert.strictEqual Object.keys( currentFailedTest ).length, 1

# New failed test # mybuild.test1 fails again and mybuild.test3 is new
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test1', 'mybuild.test2', 'mybuild.test3' ] )
assert.strictEqual Object.keys( fixedTests ).length, 0
assert.strictEqual Object.keys( newFailedTest ).length, 2
assert newFailedTest['mybuild.test3']
assert.strictEqual Object.keys( currentFailedTest ).length, 3

# 1 fixed
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test2', 'mybuild.test3' ] )
assert.strictEqual Object.keys( fixedTests ).length, 1
assert fixedTests['mybuild.test1']
assert.strictEqual Object.keys( newFailedTest ).length, 0
assert.strictEqual Object.keys( currentFailedTest ).length, 2

# 1 new, 1 fixed
[fixedTests, newFailedTest, currentFailedTest]=@backend.persistFailedTests "myproject", "mybuild", toHudsonTests( [ 'mybuild.test3', 'mybuild.test4' ] )
assert.strictEqual Object.keys( fixedTests ).length, 1
assert fixedTests['mybuild.test2']
assert.strictEqual Object.keys( newFailedTest ).length, 1
assert newFailedTest['mybuild.test4']
assert.strictEqual Object.keys( currentFailedTest ).length, 2

[failedTest, unassigned, assigned] = @backend.getFailedTests "myproject"
assert.strictEqual Object.keys( failedTest ).length, 2
assert failedTest['mybuild.test3']
assert failedTest['mybuild.test4']

@backend.assignTests "myproject", [ 'mybuild.test3' ], "myuser"
[failedTest, unassigned, assigned] = @backend.getFailedTests "myproject"
assert.strictEqual failedTest['mybuild.test3'].assigned, "myuser"

assignedTests = @backend.getAssignedTests "myuser"
assert.strictEqual Object.keys( assignedTests ).length, 1
assert.strictEqual Object.keys( assignedTests["myproject"].failedtests ).length, 1
assert assignedTests["myproject"].failedtests['mybuild.test3']
assert.strictEqual assignedTests["myproject"].failedtests['mybuild.test3'].assigned, "myuser"

console.log "Success"