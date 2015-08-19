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

Feature: Group memberships
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And there is 1 user with the following:
      | login     | bob        |
      | firstname | Bob        |
      | Lastname  | Bobbit     |
    And there is 1 user with the following:
      | login     | alice      |
      | firstname | Alice      |
      | lastname  | Wonderland |
    And there is 1 group with the following:
      | name      | group1     |
    And there is a role "alpha"
    And there is a role "beta"
    And the role "alpha" may have the following rights:
      | manage_members |
    And the user "bob" is a "alpha" in the project "project1"

  @javascript
  Scenario: Adding a group with members to a project
    Given the group "group1" has the following members:
      | alice     |
    And I am already logged in as "bob"
    When I go to the members tab of the settings page of the project "project1"
    And I add the principal "group1" as a member with the roles:
      | beta |
    Then I should see the principal "group1" as a member with the roles:
      | beta |
    And I should see the principal "alice" as a member with the roles:
      | beta |

  Scenario: Adding members to a group after the group has been added to the project adds the users to the project
    Given the group "group1" is a "beta" in the project "project1"
    And I am already admin
    When I go to the edit page of the group called "group1"
    And I follow "Users" within ".tabs"
    And I add the user "alice" to the group
    And I go to the members tab of the settings page of the project "project1"
    Then I should see the principal "group1" as a member with the roles:
      | beta |
    And I should see the principal "alice" as a member with the roles:
      | beta |

  @javascript
  Scenario: Removing a group from a project removes its members (users) as well if they have no roles of their own
    Given the group "group1" has the following members:
      | alice     |
    And the group "group1" is a "beta" in the project "project1"
    And I am already logged in as "bob"
    When I go to the members tab of the settings page of the project "project1"
    And I follow the delete link of the project member "group1"
    Then I should not see the principal "group1" as a member
    And I should not see the principal "alice" as a member

  @javascript
  Scenario: Removing a group from a project leaves a member if he has other roles besides those inherited from the group
    Given the group "group1" has the following members:
      | alice     |
    And the user "alice" is a "alpha" in the project "project1"
    And the group "group1" is a "beta" in the project "project1"
    And I am already logged in as "bob"
    When I go to the members tab of the settings page of the project "project1"
    And I follow the delete link of the project member "group1"
    Then I should not see the principal "group1" as a member
    And I should see the principal "alice" as a member with the roles:
      | alpha |


