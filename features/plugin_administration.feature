Feature: Plugin Administration
  As an Admin
  I want to administer the plugin
  So that it can be adjusted to the user_specific needs

  Scenario: Fields for configuration
    Given I am admin
    When I go to the backlogs plugin configuration page
    Then there should be a "settings_card_spec" field