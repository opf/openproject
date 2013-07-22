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

Feature: Tracking Time

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
      | identifier  | project1      |
    And I am working in project "parent"
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a role "member"
    And there is an activity "Development"
    And there is an activity "Design"
    And the role "member" may have the following rights:
      | add_issues  |
      | view_work_packages |
      | edit_work_packages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 1 issue with the following:
      |  subject      | issue1             |
      |  due_date     | 2012-05-04         |
      |  start_date   | 2011-05-04         |
      |  description  | Aioli Sali Grande  |
    And there is a time entry for "issue1" with 4 hours
    And I am logged in as "admin"
    And I am on the time entry page of issue "issue1"

  Scenario: Adding a time entry
    When I log 2 hours with the comment "test"
    Then I should see a time entry with 2 hours and comment "test"
    And I should see a total spent time of 6 hours

  Scenario: Editing a time entry
    When I update the first time entry with 4 hours and the comment "updated test"
    Then I should see a time entry with 4 hours and comment "updated test"
    And I should see a total spent time of 4 hours

