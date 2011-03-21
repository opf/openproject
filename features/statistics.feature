Feature: Scrum statistics
  As a product owner
  I want to see scrum statistics
  So that I am able to check the performance of the team

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | mathias |
    And there is a role "product owner"
    And the role "product owner" may have the following rights:
        | view_scrum_statistics |
    And the user "mathias" is a "product owner"
    And there is 1 user with:
        | login | andre |
    And there is a role "visitor"
    And the role "visitor" has no permissions
    And the user "andre" is a "visitor"

  Scenario: View scrum statistics
    Given the scrum statistics are enabled
      And I am logged in as "mathias"
     When I go to the home page
      And I follow "Scrum statistics"
     Then I should be on the scrum statistics page

  Scenario: Hide scrum statistics
    Given the scrum statistics are enabled
      And I am logged in as "andre"
     When I go to the home page
     Then I should not see "Scrum statistics" within "#main-menu"

  Scenario: Deactivate scrum statistics
    Given the scrum statistics are disabled
      And I am logged in as "mathias"
     When I go to the home page
     Then I should not see "Scrum statistics" within "#main-menu"
