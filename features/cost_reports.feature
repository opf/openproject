Feature: Cost Reports

  Scenario: Anonymous user sees no costs
    Given I am not logged in
    And there is one Project with the following:
      | Name | Test |
      | Identifier | test |
    And the project called Test uses the following modules:
      | Issue Tracking |
      | Time Tracking |
      | Cost Control |
    And there is one fixed cost object with the following:
      | Subject | "Something" |
    And I am on the Cost Reports page for the project called Test
    Then I should not see "Something"
    
  Scenario: Admin user sees everything
    Given I am admin
    And there is one project with the following:
      | Name | Test |
      | Identifier | test |
    And the project called Test uses the following modules:
      | Issue Tracking |
      | Time Tracking |
      | Cost Control |
    And there is one fixed cost object with the following:
      | Subject | "Something" |
    And I am on the Cost Reports page for the project called Test
    Then I should see "Something"

      