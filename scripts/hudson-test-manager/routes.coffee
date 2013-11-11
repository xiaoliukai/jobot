class HudsonTestManagerRoutes

  # Constants for "routes"
  @BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$ = /Broadcast failed tests for project (\w*) to room (\w*)/i
  
  # TODO Implement and test the following RegEx
  @STOP_BROADCASTING_FAILED_TESTS_FOR_PROJECT_$_TO_ROOM_$ = /Stop broadcasting failed tests for project {} to room {}/i
  @WATCH_FAILED_TESTS_FOR_PROJECT_$_USING_BUILD_$ = /Watch failed tests for project {} using build {}/i
  @STOP_WATCHING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$ = /Stop watching failed tests of build {} for project {}/i
  @SET_MANAGER_FOR_PROJECT_$_TO_$ = /Set manager for project {} to {}/i
  @SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY = /Set {warning|escalade} test fix delay for project {} to {} {hour|day}(s)/i
  @ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME = /Assign {1 | 1-4 | 1, 3 | com.eightd.some.test} (of project {}) to {me | someuser}/i
  @SHOW_TEST_REPORT_FOR_PROJECT_$ = /Show test report for project {}/i
  
module.exports = HudsonTestManagerRoutes 