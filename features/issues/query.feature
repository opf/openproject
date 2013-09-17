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

Feature: Work Package Query
  Background:
    And there is 1 project with the following:
      | name       | project |
      | identifier | project |
    And I am working in project "project"
    And the project "project" has the following types:
      | name | position |
      | Bug  |     1    |

  @javascript
  Scenario: Create a query and give it a name
    When I am already admin
     And I go to the work packages index page for the project "project"
     And I follow "Save" within "#query_form"
     And I fill in "Query" for "Name"
     And I press "Save"
    Then I should see "Query" within "#content"
     And I should see "Successful creation."
  
  @javascript
  Scenario: Group on empty Value (Assignee)
    Given the project "project" has 1 issue with the following:
      | subject | issue1 |
     And I am already admin
     And I go to the work packages index page for the project "project"
     And I follow "Options" within "#query_form"
     And I select "Assignee" from "group_by"
     And I follow "Apply"
     And I follow "Save"
     And I fill in "Query" for "Name"
     And I press "Save"
    Then I should see "Query" within "#content"
     And I should see "Successful creation."
     And I should see "None" within "#content"

  Scenario: Save Button should be visible for users with the proper rights
    Given there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
    And there is a role "member_with_privileges"
    And the role "member_with_privileges" may have the following rights:
      | view_work_packages |
      | save_queries       |
    And the user "bob" is a "member_with_privileges" in the project "project"
    When I am already logged in as "bob"
     And I go to the work packages index page for the project "project"
    Then I should see "Save" within "#query_form"

  Scenario: Save Button should be invisible for users without the proper rights
    Given there is 1 user with the following:
      | login     | alice  |
      | firstname | Alice  |
      | lastname  | Alison |
    And there is a role "member_without_privileges"
    And the role "member_without_privileges" may have the following rights:
      | view_work_packages |
    And the user "alice" is a "member_without_privileges" in the project "project"
    When I am already logged in as "alice"
     And I go to the work packages index page for the project "project"
    Then I should not see "Save" within "#query_form"
