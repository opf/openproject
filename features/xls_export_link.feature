Feature: Show link to XLS format below issue list

  Scenario: There is a link to the issue list in XML format
    Given there is a project named "Test Project"
    And I am already admin
    When I go to the issues index page for the project "Test Project"
    Then there should be a link to the issue list in XLS format
