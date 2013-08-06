#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Relating issues to each other

  Background:
    Given there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_issues   |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 1 issue with the following:
      | subject | Some Issue |
      | type    | Bug |
    And the user "bob" has 1 issue with the following:
      | subject | Another Issue |
      | type    | Bug |
    And I am already admin

  @javascript
  Scenario: Adding a relation will add it to the list of related issues through AJAX instantly
    When I go to the page of the issue "Some Issue"
    And I click on "Add related work package"
    And I fill in "relation_issue_to_id" with "2"
    And I press "Add"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the issue "Some Issue"
    And I should see "related to Bug #2: Another Issue"

  @javascript
  Scenario: Adding a relation to an issue with special chars in subject should not end in broken html
    Given the user "bob" has 1 issue with the following:
      | subject | Anothe'r & Issue |
      | type    | Bug |
    When I go to the page of the issue "Some Issue"
    And I click on "Add related work package"
    And I fill in "relation_issue_to_id" with "3"
    And I press "Add"
    And I wait for the AJAX requests to finish
    Then I should be on the page of the issue "Some Issue"
    And I should see "related to Bug #3: Anothe'r & Issue"

