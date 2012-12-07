Feature: Issue textile quickinfo links
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And there is a role "member"
    And the role "member" may have the following rights:
      | add_issues  |
      | view_issues |
    And there is 1 user with the following:
      | login | bob|
    And the user "bob" is a "member" in the project "parent"
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
      | In Progress | false      | false       |
    Given the user "bob" has 1 issue with the following:
      |  subject      | issue1             |
      |  due_date     | 2012-05-04         |
      |  start_date   | 2011-05-04         |
      |  description  | Aioli Sali Grande  |
    And I am already logged in as "bob"

  Scenario: Adding an issue link
    When I go to the issues/new page of the project called "parent"
    And I fill in "One hash key" for "issue_subject"
    And I fill in the ID of "issue1" with 1 hash for "issue_description"
    And I press "Create"
    Then I should see an issue link for "issue1" within "div.wiki"
    When I follow the issue link with 1 hash for "issue1"
    Then I should be on the page of the issue "issue1"

  Scenario: Adding an issue quickinfo link
    When I go to the issues/new page of the project called "parent"
    And I fill in "One hash key" for "issue_subject"
    And I fill in the ID of "issue1" with 2 hash for "issue_description"
    And I press "Create"
    Then I should see a quickinfo link for "issue1" within "div.wiki"
    When I follow the issue link with 2 hash for "issue1"
    Then I should be on the page of the issue "issue1"

  Scenario: Adding an issue quickinfo link with description
    When I go to the issues/new page of the project called "parent"
    And I fill in "One hash key" for "issue_subject"
    And I fill in the ID of "issue1" with 3 hash for "issue_description"
    And I press "Create"
    Then I should see a quickinfo link with description for "issue1" within "div.wiki"
    When I follow the issue link with 3 hash for "issue1"
    Then I should be on the page of the issue "issue1"
