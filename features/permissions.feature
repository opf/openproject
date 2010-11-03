Feature: Permissions
#XXX: Test permissions on table and simple table (currently testet in _cost_entry_table partial only)
#XXX: Test access permissions for /cost_reports AND /project/../cost_reports - sometimes there is access denied where is should not and vice versa

  @changes_environment
  Scenario: Enabling the debug-flag doesn't work in production mode
    When we can finally switch the ruby environment within our cukes
    Given there is a standard permission test project named "Permission_Test"
    And I am in "production" mode
    And I am admin
    And I am on the overall Cost Reports page with standard groups in debug mode
    And I start debugging
    Then I should not see "[ RESULT ]"
    And I should not see "[ Query ]"

  @changes_environment
  Scenario: Enabling the debug-flag works in development mode
    Given there is a standard permission test project named "Permission_Test"
    And I am in "development" mode
    And I am admin
    And I am on the overall Cost Reports page with standard groups in debug mode
    Then I should see "[ RESULT ]"
    And I should see "[ Query ]"