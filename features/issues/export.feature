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

Feature: Exporting issues

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
    And I am logged in as "bob"

  Scenario: No export links on project issues index if user has no "export_issues" permission
    When I go to the issues index page of the project called "project1"
    Then I should not see "CSV"
    And I should not see "PDF"

  Scenario: Export links on project issues index if user has the "export_issues" permission
    Given the role "member" may have the following rights:
     | view_issues   |
     | export_issues |
    When I go to the issues index page of the project called "project1"
    Then I should see "CSV" within ".other-formats"
    And I should see "PDF" within ".other-formats"

  Scenario: No export links on global issues index if user has no "export_issues" permission
    When I go to the global index page of issues
    Then I should not see "CSV"
    And I should not see "PDF"

  Scenario: Export links on global issues index if user has the "export_issues" permission
    Given the role "member" may have the following rights:
     | view_issues   |
     | export_issues |
    When I go to the global index page of issues
    Then I should see "CSV" within ".other-formats"
    And I should see "PDF" within ".other-formats"




