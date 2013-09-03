Feature: Show link to XLS format below work package list

  Scenario: There is a link to the work package list in XML format
    Given there is a project named "Test Project"
    And I am already admin
    When I go to the work packages index page for the project "Test Project"
    Then there should be a link to the work package list in XLS format
    And there should be a link to the work package list in XLS format with descriptions
