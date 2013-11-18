#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Global Create Project

  Scenario: Create Project is not a member permission
    Given there is a role "Member"
    And I am already admin
    When I go to the edit page of the role "Member"
    Then I should not see "Create project"

  Scenario: Create Project is a global permission
    Given there is a global role "Global"
    And I am already admin
    When I go to the edit page of the role "Global"
    Then I should see "Create project"

  Scenario: Create Project displayed to user
    Given there is a global role "Global"
    And the global role "Global" may have the following rights:
      | add_project |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "Global"
    When I am already logged in as "bob"
    And I go to the overall projects page
    Then I should see "New project"

  Scenario: Create Project not displayed to user without global role
    Given there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    When I am already logged in as "bob"
    And I go to the overall projects page
    Then I should not see "New project"

  Scenario: Create Project displayed to user
    Given there is a global role "Global"
    And the global role "Global" may have the following rights:
      | add_project |
    And there is a role "Manager"
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "Global"
    When I am already logged in as "bob"
    And I go to the new page of "Project"
    And I fill in "project_name" with "ProjectName"
    And I fill in "project_identifier" with "projectid"
    And I press "Save"
    Then I should see "Successful creation."
    And I should be on the settings page of the project called "ProjectName"
