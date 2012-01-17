Feature: Adding widgets to the page

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
    And I am admin
    And I am on the project "project1" overview personalization page

  @javascript
  Scenario: Adding a "Watched issues" widget
   When I select "Watched issues" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Watched issues" widget should be in the hidden block
    And "Watched issues" should be disabled in the available widgets drop down

