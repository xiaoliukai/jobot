class HudsonTestManagerRoutes

  # Constants for "routes"
  @STOP_ING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$ = /TODO/i #Missing constant
  @BROADCAST_FAILED_TESTS_FOR_PROJETS_$_TO_ROOM_$ = /Broadcast failed tests for project (\S*) to room (\S*)/i
  @STOP_BROADCASTING_FAILED_TESTS_FOR_PROJECT_$_TO_ROOM_$ = /Stop broadcasting failed tests for project (\S*) to room (\S*)/i
  @WATCH_FAILED_TESTS_FOR_PROJECT_$_USING_BUILD_$ = /Watch failed tests for project (\S*) using build (\S*)/i
  @STOP_WATCHING_FAILED_TESTS_OF_BUILD_$_FOR_PROJECT_$ = /Stop watching failed tests of build (\S*) for project (\S*)/i
  @SET_MANAGER_FOR_PROJECT_$_TO_$ = /Set manager for project (\S*) to (\S*)/i
  @SET_WARNING_OR_ESCALADE_TEST_FIX_DELAY_FOR_PROJECT_$_TO_$_HOURS_OR_DAY = /Set (warning|escalade) test fix delay for project (\S*) to (\d*) (hour|day)s?/i
  @ASSIGN_TESTS_OF_PROJECT_$_TO_$_OR_ME = /Assign (.*?)(?: of project (\S*))? to (me|((\S*)\s?)+)/i
  @SHOW_TEST_ASSIGNED_TO_ME = /Show tests? assigned to me/i
  @SHOW_TEST_REPORT_FOR_PROJECT_$ = /Show tests? (?:report )?(?:for )?(?:project )?(\S*)/i
  @SHOW_UNASSIGNED_TEST_FOR_PROJECT_$ = /Show unassigned tests? for (?:project )?(\S*)/i
  
module.exports = HudsonTestManagerRoutes 