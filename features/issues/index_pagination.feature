Feature: Paginated issue index list

  Background:
    Given there is 1 project with the following:
      | identifier | project1 |
      | name       | project1 |
    And there is 1 user with the following:
      | login      | bob      |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_issues   |
      | create_issues |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 26 issues with the following:
      | subject    | Issuesubject |
    And I am already logged in as "bob"

  Scenario: Pagination within a project
    When I go to the issues index page of the project "project1"
    Then I should see 25 issues
    When I follow "2" within ".pagination"
    Then I should be on the issues index page of the project "project1"
    And I should see 1 issue

  Scenario: Pagination outside a project
    When I go to the global index page of issues
    Then I should see 25 issues
    When I follow "2" within ".pagination"
    Then I should be on the global index page of issues
    And I should see 1 issue
