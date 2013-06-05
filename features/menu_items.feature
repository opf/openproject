Feature: Menu items
  Background:
    Given there is 1 project with the following:
      | name            | Awesome Project      |
      | identifier      | awesome-project      |
    And project "Awesome Project" uses the following modules:
      | calendar |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_calendar  |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And I am logged in as "bob"

  Scenario: Calendar menu should be visible when calendar is activated
    When I go to the overview page of the project "Awesome Project"
    Then I should see "Calendar" within "#main-menu"
