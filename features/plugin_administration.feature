Feature: Plugin Administration
  As an Admin
  I want to administer the plugin
  So that it can be adjusted to the user_specific needs

  Scenario: Fields for configuration
    Given I am already admin
    When I go to the configuration page of the "openproject_backlogs" plugin
    Then there should be a "settings_card_spec" field
