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

Feature: Switching types of work packages
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And I am working in project "project1"
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | edit_work_packages |
      | add_work_packages  |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
    # prevent alerts to occur that would impede subsequent scenarios
    And the user "bob" has the following preferences
      | warn_on_leaving_unsaved | 0 |
    And the user "bob" is a "member" in the project "project1"
    And I am already logged in as "bob"

  @javascript
  Scenario: Previewing a new work package
    When I am on the new work_package page of the project called "project1"
     And I fill in the following within "#work_package_descr_fields":
       | Description | pe1 description |
     And I follow "Preview"
    Then I should see "pe1 description" within "#preview"

  @javascript
  Scenario: Previewing changes on an existing work package
    Given there are the following work packages in project "project1":
      | subject  | description     |
      | pe1      | pe1 description |
    When I am on the edit page of the work package called "pe1"
     And I follow "More"
     And I fill in the following:
       | Description | pe1 description changed |
       | Notes       | Update note             |
     And I follow "Preview"
    Then I should see "pe1 description changed" within "#preview"
    Then I should see "Update note" within "#preview"
