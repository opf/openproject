#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Project Settings
  Background:
    Given there are the following project types:
      | Name         | Allows Association |
      | Copy Project | true               |
    And there are the following projects of type "Copy Project":
      | project1 |
    And there is 1 user with the following:
      | login     | bob        |
      | firstname | Bob        |
      | Lastname  | Bobbit     |
    And there is 1 user with the following:
      | login     | alice      |
      | firstname | Alice      |
      | Lastname  | Alison     |
    And there is a role "alpha"
    And there is a role "beta"
    And the role "alpha" may have the following rights:
      | copy_projects |
      | edit_project  |
    And the role "beta" may have the following rights:
      | edit_project  |
    And the user "alice" is a "alpha" in the project "project1"
    And the user "bob" is a "beta" in the project "project1"
    And Delayed Job is turned off

  Scenario: Check for the existence of a copy button
    When I am already admin
    And  I go to the settings page of the project "project1"
    Then I should see "Copy" within "#content"

  Scenario: Permission test for copy button with authorized role
    When I am already logged in as "alice"
    And  I go to the settings page of the project "project1"
    Then I should see "Copy" within "#content"

  Scenario: Permission test for copy button without authorized role
    When I am already logged in as "bob"
    And  I go to the members tab of the settings page of the project "project1"
    Then I should not see "Copy" within "#content"

  @javascript
  Scenario: Copy a project with parent
    Given there are the following projects of type "Copy Project":
      | project2 |
    When I am already admin
    And  I go to the settings page of the project "project1"
    And  I select "project2" from "Subproject of"
    And  I click on "Save" within "#content"
    And  I follow "Copy" within "#content"
    And  I fill in "Name" with "Copied Project"
    And  I click on "Copy"
    Then I should see "Started to copy project"
    And  I go to the settings page of the project "copied-project"
    And  I should see "project2" within "#project_parent_id"

  @javascript
  Scenario: Copy a project with types
    Given the following types are enabled for the project called "project1":
        | Name      |
        | Phase1    |
        | Phase2    |
    And  I am already admin
    And  I go to the settings page of the project "project1"
    And  I follow "Copy" within "#content"
    And  I fill in "Name" with "Copied Project"
    And  I click on "Copy"
    Then I should see "Started to copy project"
    And  I go to the settings page of the project "copied-project"
    And  I follow "Types" within "#content"
    Then the "Phase1" checkbox should be checked
    And  the "Phase2" checkbox should be checked

  @javascript
  Scenario: Copy a project with Custom Fields
    Given the following work package custom fields are defined:
      | name  | type | editable | is_for_all |
      | cfBug | int  | true     | false      |
    And  I am already admin
    And  I go to the custom_fields tab of the settings page of the project "project1"
    And  I check "cfBug"
    And  I press "Save"
    And  I follow "Copy"
    And  I fill in "Name" with "Copied Project"
    And  I click on "Copy"
    Then I should see "Started to copy project"
    And  I go to the custom_fields tab of the settings page of the project "copied-project"
    Then the "cfBug" checkbox should be checked

  @javascript
  Scenario: Copying a project with some issues
    Given the project "project1" has 1 issue with the following:
      | subject | issue1 |
    And   the project "project1" has 1 issue with the following:
      | subject | issue2 |
    When  I am already admin
    And   I go to the settings page of the project "project1"
    And   I follow "Copy" within "#content"
    And   I fill in "Name" with "Copied Project"
    And   I check "Work packages"
    And   I click on "Copy"
    Then  I should see "Started to copy project"
    And   I go to the work packages index page for the project "Copied Project"
    Then  I should see "issue1" within "#content"
    And   I should see "issue2" within "#content"

  @javascript
  Scenario: Copying a project with a complex issue
    Given the project "project1" has 1 version with:
      | name           | version1   |
      | description    | yeah, boy  |
      | start_date     | 2001-08-02 |
      | effective_date | 2002-08-02 |
    And the project "project1" has 1 category with:
      | assigned_to | Carl      |
      | name        | issue_cat |
    And the following types are enabled for the project called "project1":
      | Name    |
      | Phase 1 |
    And there are the following issues in project "project1":
      | subject | assignee | type    | version  | responsible | done_ratio | description | category  |
      | foo     | alice    | Phase 1 | version1 | bob         | 20         | Description | issue_cat |
    When I am already admin
    And  I go to the settings page of the project "project1"
    And  I follow "Copy" within "#content"
    And  I fill in "Name" with "Copied Project"
    And  I check "Work packages"
    And  I click on "Copy"
    Then I should see "Started to copy project"
    And I go to the page of the issue "foo"
    Then I should see "Alice Alison" within "#content"
    And  I should see "foo" within "#content"
    And  I should see "Bob Bobbit" within "#content"
    And  I should see "version1" within "#content"
    And  I should see "Description" within "#content"
    And  I should see "issue_cat" within "#content"
    And  I should see "20" within "#content"
