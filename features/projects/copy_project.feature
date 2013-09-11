Feature: Project Settings
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |

  Scenario: Check for the existence of a copy button
    When I am already admin
    And  I go to the members tab of the settings page of the project "project1"
    Then I should see "Copy" within ".action_menu_main"