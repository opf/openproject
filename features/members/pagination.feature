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
      And there is 1 user with the following:
        | login     | bob        |
        | firstname | Bob        |
        | Lastname  | Bobbit     |
      And there is 1 user with the following:
        | login     | alice      |
        | firstname | Alice      |
        | Lastname  | Alison     |
      And the user "bob" is a "Manager" in the project "project1"
      And the user "alice" is a "Developer" in the project "project1"

  @javascript
  Scenario: Paginating after adding a member
    Given we paginate after 2 items
    When I go to the members tab of the settings page of the project "project1"
     And I add the principal "peter" as "Manager"
    When I follow "2" within ".legacy-pagination"
    Then I should see "Peter Pan"

  @javascript
  Scenario: Paginating after removing a member
    Given we paginate after 1 items
    And the user "peter" is a "Manager" in the project "project1"
    When I go to the members tab of the settings page of the project "project1"
     And I delete the "Alice Alison" membership
    Then I should see "Bob Bobbit"
    When I follow "2" within ".legacy-pagination"
    Then I should see "Peter Pan"

 @javascript
  Scenario: Paginating after updating a member
    Given we paginate after 1 items
   When I go to the members tab of the settings page of the project "project1"
    And I click on "Edit"
    And I check "Manager"
    And I click "Change"
    And I follow "2" within ".legacy-pagination"
   Then I should see "Bob Bobbit"
