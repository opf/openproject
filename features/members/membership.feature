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

Feature: Membership

  Background:
    Given I am already admin

    Given there is a role "Manager"
      And there is a role "Developer"

      And there is 1 project with the following:
        | Identifier | project1 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

      And there is 1 User with:
        | Login     | hannibal |
        | Firstname | Hannibal |
        | Lastname  | Smith    |

      And there is 1 User with:
        | Login     | crash                          |
        | Firstname | <script>alert('h4x');</script> |
        | Lastname  | <script>alert('h4x');</script> |

      And there is a group named "A-Team" with the following members:
        | peter    |
        | hannibal |

  @javascript
  Scenario: Adding and Removing a Group as Member, non impaired
     When I go to the members tab of the settings page of the project "project1"
      And I add the principal "A-Team" as "Manager"
     Then I should be on the members tab of the settings page of the project "project1"
      And I should see "Successful creation." within ".flash.notice"
      And I should see "A-Team" within ".members"

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish
     Then I should see "No data to display"

  @javascript
  Scenario: Adding and removing a User as Member, non impaired
     When I go to the members tab of the settings page of the project "project1"
      And I add the principal "Hannibal Smith" as "Manager"
     Then I should see "Successful creation." within ".flash.notice"
      And I should see "Hannibal Smith" within ".members"

     When I delete the "Hannibal Smith" membership
      And I wait for the AJAX requests to finish
     Then I should see "No data to display"

  @javascript
  Scenario: Entering a Username as Member in firstname, lastname order, non impaired
     When I go to the members tab of the settings page of the project "project1"
      And I enter the principal name "Hannibal S"
      Then I should see "Hannibal Smith"

  @javascript
  Scenario: Entering a Username as Member in lastname, firstname order, non impaired
     When I go to the members tab of the settings page of the project "project1"
      And I enter the principal name "Smith, H"
      Then I should see "Hannibal Smith"

  @javascript
  Scenario: Escaping should work properly when entering a name
     When I go to the members tab of the settings page of the project "project1"
     And  I enter the principal name "script"
     Then I should not see an alert dialog
      And I should see "<script>alert('h4x');</script>"

  @javascript
  Scenario: Escaping should work properly when selecting a user
     When I go to the members tab of the settings page of the project "project1"
     When I select the principal "script"
     Then I should not see an alert dialog
      And I should see "<script>alert('h4x');</script>"

  @javascript
  Scenario: Adding and Removing a Group as Member, impaired
     When I am impaired
      And I go to the members tab of the settings page of the project "project1"
      And I add the principal "A-Team" as "Manager"
      And I go to the members tab of the settings page of the project "project1"
      Then I should not see "A-Team" within "#principal_results"
      And I should see "A-Team" within ".members"

  @javascript
  Scenario: User should not appear in members form if he/she is already a member of the project, impaired
     When I am impaired
      And I go to the members tab of the settings page of the project "project1"
      And I add the principal "A-Team" as "Manager"
     Then I should be on the members tab of the settings page of the project "project1"
      And I should see "Successful creation." within ".flash.notice"
      And I should see "A-Team" within ".members"

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish
     Then I should see "No data to display"

  @javascript
  Scenario: Entering a Username as Member in firstname, lastname order, impaired
     When I am impaired
      And I go to the members tab of the settings page of the project "project1"
      And I enter the principal name "Hannibal S"
      Then I should see "Hannibal Smith"

  @javascript
  Scenario: Entering a Username as Member in lastname, firstname order, impaired
     When I am impaired
      And I go to the members tab of the settings page of the project "project1"
      And I enter the principal name "Smith, H"
      Then I should see "Hannibal Smith"

  @javascript
  Scenario: Adding and removing a User as Member, impaired
     When I am impaired
      And I go to the members tab of the settings page of the project "project1"
      And I add the principal "Hannibal Smith" as "Manager"
     Then I should see "Successful creation." within ".flash.notice"
      And I should see "Hannibal Smith" within ".members"

     When I delete the "Hannibal Smith" membership
      And I wait for the AJAX requests to finish
     Then I should see "No data to display"
