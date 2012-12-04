Feature: User deletion

  @javascript
  Scenario: A user can delete himself if the setting permitts it
    Given the "users_deletable_by_self" setting is set to true
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "bob"
    And I go to the my account page
    And I follow "Delete account"
    And I press "Delete"
    And I accept the alert dialog
    Then I should see "Account successfully deleted"
    And I should be on the login page

  Scenario: A user can not delete himself if the setting forbidds it
    Given the "users_deletable_by_self" setting is set to false
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "bob"
    And I go to the my account page
    Then I should not see "Delete account" within "#main-menu"

  @javascript
  Scenario: An admin can delete other users if the setting permitts it
    Given the "users_deletable_by_admins" setting is set to true
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "admin"
    When I go to the edit page of the user "bob"
    And I follow "Delete" within ".contextual"
    And I press "Delete"
    And I accept the alert dialog
    Then I should see "Account successfully deleted"
    And I should be on the index page of users

  Scenario: An admin can not delete other users if the setting forbidds it
    Given the "users_deletable_by_admins" setting is set to false
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "admin"
    And I go to the edit page of the user "bob"
    Then I should not see "Delete" within ".contextual"

  Scenario: Deletablilty settings can be set in the users tab of the settings
    Given I am already logged in as "admin"
    And the "users_deletable_by_admins" setting is set to false
    And the "users_deletable_by_self" setting is set to false
    And I go to the users tab of the settings page
    And I check "settings_users_deletable_by_admins"
    And I check "settings_users_deletable_by_self"
    And I press "Save"
    Then the "users_deletable_by_admins" setting should be true
    Then the "users_deletable_by_self" setting should be true
