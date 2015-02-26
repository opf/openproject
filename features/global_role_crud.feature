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

Feature: As an admin
         I want to administrate global roles with permissions
         So that I can modify permission groups

  @javascript
  Scenario: Global Role creation
    Given there is the global permission "glob_test" of the module "global_group"
    And I am already admin
    When I go to the new page of "Role"
    Then I should not see block with "#global_permissions"
    When I check "Global Role"
    Then I should see block with "#global_permissions"
    And I should see "Global group"
    And I should see "Glob test"
    And I should not see "Issues can be assigned to this role"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Successful creation."

  Scenario: Global Roles can not be assigned issues to
    Given there is a global role "global_role_x"
    And I am already admin
    When I go to the edit page of the role called "global_role_x"
    Then I should not see "Issues can be assigned to this role"
