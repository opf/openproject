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

Feature: Error Messages

  Background:
    Given I am already admin

    Given there is a role "Manager"

      And there is 1 project with the following:
        | Name       | Project1 |
        | Identifier | project1 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

  @javascript
  Scenario: Adding a Principal, non impaired
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the principal "Peter Pan"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 error messages

  @javascript
  Scenario: Adding a Role, non impaired
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the role "Manager"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 error messages

  @javascript
  Scenario: Adding a Principal, impaired
     When I am impaired
      And I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the principal "Peter Pan"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 error messages

  @javascript
  Scenario: Adding a Role, impaired
     When I am impaired
      And I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the role "Manager"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 error messages

  @javascript
  Scenario: Removing old error or success messages when adding members
    Given there is 1 User with:
      | Login     | tinkerbell |
      | Firstname | Tinker     |
      | Lastname  | Bell       |
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the principal "Peter Pan"
      And I select the role "Manager"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then there should be a flash notice message
      And there should not be any error message

      Then I select the principal "Tinker Bell"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 error message
      And there should not be a flash notice message
