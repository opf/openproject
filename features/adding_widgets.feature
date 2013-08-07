Feature: Adding widgets to the page

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
    And there is a role "Admin"
    And there is a role "Manager"
    And I am already Admin
    And I am on the project "project1" overview personalization page

  Scenario: I should see the available widgets
    Then I should see the dropdown of available widgets

  @javascript
  Scenario: Adding a "Watched issues" widget
   When I select "Watched issues" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Watched issues" widget should be in the hidden block
    And "Watched issues" should be disabled in the available widgets drop down

