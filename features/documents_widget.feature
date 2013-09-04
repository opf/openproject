Feature: Adding the document widget to personalisable pages

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
    And I am already Admin

  @javascript
  Scenario: Adding a "Documents" widget to the my project page
    Given the plugin "openproject_my_project_page" is loaded
    And I am on the project "project1" overview personalization page
    When I select "Documents" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Documents" widget should be in the hidden block
    And "Documents" should be disabled in the my project page available widgets drop down

  @javascript
  @firebug
  Scenario: Adding a "Documents" widget to the my page
    And I am on the My page personalization page
    When I select "Documents" from the available widgets drop down
    And I click on "Add"
    And I wait for the AJAX requests to finish
    Then the "Documents" widget should be in the top block
    And "Documents" should be disabled in the my page available widgets drop down
