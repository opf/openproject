#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

# This addresses some of the forms of the admin's user panel
#
Feature: User

  Background:
    Given I am already admin

    Given there is a role "Manager"
      And there is a role "Developer"

      And there is 1 project with the following:
        | Identifier | project1 |
        | name       | Project1 |
      And there is 1 project with the following:
        | Identifier | project2 |
        | name       | Project2 |
      And there is 1 project with the following:
        | Identifier | project3 |
        | name       | Project3 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

      And there is 1 User with:
        | Login     | hannibal |
        | Firstname | Hannibal |
        | Lastname  | Smith    |

    And there is a role "alpha"
    And there is a role "beta"
    And there is a role "gamma"

  @javascript
  Scenario: Granting Membership to a project with one role
    When I go to the memberships tab of the edit page for the user peter
    And I select "Project1" from "membership_project_id"
    And I check the role "alpha"
    And I click "Add" within "#new_project_membership"
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    And I should not see membership to the project "project2"

  @javascript
  Scenario: Granting Membership to a project with multiple
    When I go to the memberships tab of the edit page for the user peter
    And I select "Project1" from "membership_project_id"
    And I check the role "alpha"
    And I check the role "beta"
    And I check the role "gamma"
    And I click "Add" within "#new_project_membership"
    Then I should see membership to the project "project1" with the roles:
      | alpha |
      | beta  |
      | gamma |
    And I should not see membership to the project "project2"

  @javascript
  Scenario: Revoking Membership to a project
    When the user "peter" is a "alpha" in the project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    When I delete membership to project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should not see membership to the project "project1"

  @javascript
  Scenario: Editing membership to a project
    When the user "peter" is a "alpha" in the project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    When I edit membership to project "project1" to contain the roles:
      | alpha |
      | beta  |
      | gamma |
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
      | beta  |
      | gamma |

  @javascript
  Scenario: re-adding a Member inside Admin Panel
    When the user "peter" is a "alpha" in the project "project1"
     And I go to the memberships tab of the edit page for the user peter
    When I delete membership to project "project1"
    Then I should see "Please select"
     And I select "Project1" from "membership_project_id"
     And I check the role "alpha"
     And I click "Add" within "#new_project_membership"
     Then I should see membership to the project "project1" with the roles:
       | alpha |
