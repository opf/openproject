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

Feature: Group Memberships

  Background:
    Given I am already admin

    Given there is a role "Manager"
      And there is a role "Developer"

      And there is 1 project with the following:
        | Name       | Project1 |
        | Identifier | project1 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

      And there is 1 User with:
        | Login     | hannibal |
        | Firstname | Hannibal |
        | Lastname  | Smith    |

      And there is a group named "A-Team" with the following members:
        | peter    |
        | hannibal |


  @javascript
  Scenario: Adding a group to a project on the project's page adds the group members as well
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I add the principal "A-Team" as a member with the roles:
        | Manager |
     Then I should be on the "members" tab of the settings page of the project called "Project1"
      And I should see "A-Team" within ".members"
      And I should see "Hannibal Smith" within ".members"
      And I should see "Peter Pan" within ".members"

  @javascript
  Scenario: Group-based memberships and individual memberships are handled separately
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I add the principal "Hannibal Smith" as a member with the roles:
        | Manager |
      And I wait for the AJAX requests to finish
     Then I should see "Successful creation." within ".flash.notice"

      And I add the principal "A-Team" as a member with the roles:
        | Developer |
      And I wait for the AJAX requests to finish
     Then I should see "Successful creation." within ".flash.notice"

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish

     Then I should see "Hannibal Smith" within ".members"
      And I should not see "A-Team" within ".members"
      And I should not see "Peter Pan" within ".members"


  @javascript
  Scenario: Removing a group from a project on the project's page removes all group members as well
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I add the principal "A-Team" as a member with the roles:
        | Manager |

     Then I should be on the "members" tab of the settings page of the project called "Project1"
      And I wait for the AJAX requests to finish

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish

     Then I should see "No data to display"
      And I should not see "A-Team" within ".members"
      And I should not see "Hannibal Smith" within ".members"
      And I should not see "Peter Pan" within ".members"

  @javascript
  Scenario: Adding a user to a group adds the user to projects as well
     When I go to the admin page of the group called "A-Team"
      And I click on "tab-users"
      And I delete "hannibal" from the group
      And I wait for the AJAX requests to finish

      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add" within "#tab-content-memberships"
      And I wait for the AJAX requests to finish

      And I click on "tab-users"
      And I check "Hannibal Smith"
      And I press "Add" within "#tab-content-users"
      And I wait for the AJAX requests to finish

     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should see "Peter Pan" within ".members"
      And I should see "Hannibal Smith" within ".members"


  @javascript
  Scenario: Removing a user from a group removes the user from projects as well
     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add" within "#tab-content-memberships"
      And I wait for the AJAX requests to finish

     When I click on "tab-users"
      And I delete "hannibal" from the group
      And I wait for the AJAX requests to finish

     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should not see "Hannibal Smith" within ".members"
      And I should see "Peter Pan" within ".members"

  @javascript
  Scenario: Adding a group to project on the group's page adds the group members as well
     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add" within "#tab-content-memberships"
      And I wait for the AJAX requests to finish

     Then the project member "A-Team" should have the role "Manager"

     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should see "Hannibal Smith" within ".members"
      And I should see "Peter Pan" within ".members"

  @javascript
  Scenario: Adding/Removing a group to/from a project displays success message
     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add" within "#tab-content-memberships"
      And I wait for the AJAX requests to finish

     Then I should see "Successful update." within ".notice"
      And I should see "Project1"

     When I follow "Delete" within "table.list.memberships"

     Then I should see "Successful deletion." within ".notice"
      And I should see "No data to display"
