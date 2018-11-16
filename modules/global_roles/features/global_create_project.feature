#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
    Then I should see "Project" within ".toolbar-items"

  Scenario: Create Project not displayed to user without global role
    Given there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    When I am already logged in as "bob"
    And I go to the overall projects page
    Then I should not see "Project" within ".toolbar-items"

  @javascript
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
    And I press "Create"
    Then I should see "Successful creation."
    And I should be on the overview page of the project called "ProjectName"
