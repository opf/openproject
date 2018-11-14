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

Feature: Global Role Assignment

  @javascript
  Scenario: Going to the global role assignment page
    Given there is the global permission "global1" of the module "global"
    And there is the global permission "global2" of the module "global"
    And there is a global role "global_role1"
    And there is a global role "global_role2"
    And the global role "global_role1" may have the following rights:
      | global1 |
    And the global role "global_role2" may have the following rights:
      | global2 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "global_role1"
    And I am already admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    Then I should see "global_role1" within "#table_principal_roles"
    And I should not see "global_role1" within "#available_principal_roles"
    And I should see "global_role2" within "#available_principal_roles"

  @javascript
  Scenario: Assigning a global role to a user
    Given there is the global permission "global1" of the module "global"
    And there is a global role "global_role"
    And the global role "global_role" may have the following rights:
      | global1 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And I am already admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    And I select the available global role "global_role"
    And I press "Add"
    Then I should see "global_role" within "#table_principal_roles"
    And I should not see "global_role" within "#available_principal_roles"
    And I should see "There is currently nothing to display"

  @javascript
  Scenario: Deleting a global role of a user
    Given there is the global permission "global1" of the module "global"
    And there is a global role "global_role"
    And the global role "global_role" may have the following rights:
      | global1 |
    And there is 1 User with:
      | Login | bob |
      | Firstname | Bob |
      | Lastname | Bobbit |
    And the user "bob" has the global role "global_role"
    And I am already admin
    When I go to the edit page of the user called "bob"
    And I click on "tab-global_roles"
    And I delete the assigned role "global_role"
    Then I should see "Nothing to display" within "#assigned_principal_roles"
    And I should see "global_role" within "#available_principal_roles"
