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

Feature: Watch issues
  Background:
    Given there are no issues
    And there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am working in project "parent"
    And the project "parent" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
      | admin     | true   |
    And the user "bob" is a "member" in the project "parent"
    Given the user "bob" has 1 issue with the following:
      | subject     | issue1              |
    And I am already logged in as "bob"

  @javascript
  Scenario: Watch an issue
    When I go to the page of the issue "issue1"
    Then I should see "Watch" within "#content > .action_menu_specific"
    When I click on "Watch" within "#content > .action_menu_specific"
    Then I should see "Unwatch" within "#content > .action_menu_specific"
    # The space before and after 'Watch' is important as 'Unwatch' includes the
    # string 'watch' if matched case insenstivive.
    And  I should not see " Watch " within "#content > .action_menu_specific"
     And I should see "Bob Bobbit" within "#watchers ul"
     And the issue "issue1" should have 1 watchers

  @javascript
  Scenario: Unwatch an issue
    Given the issue "issue1" is watched by:
      | bob |
    When I go to the page of the issue "issue1"
    Then I should see "Unwatch" within "#content > .action_menu_specific"
    When I click on "Unwatch" within "#content > .action_menu_specific"
    # The space before and after 'Watch' is important as 'Unwatch' includes the
    # string 'watch' if matched case insenstivive.
    Then I should see " Watch " within "#content >.action_menu_specific"
     And I should not see "Unwatch" within "#content >.action_menu_specific"
     And I should not see "Bob Bobbit" within "#watchers"
     And the issue "issue1" should have 0 watchers

  @javascript
  Scenario: Add a watcher to an issue
    When I go to the page of the issue "issue1"
    Then I should see button "Add watcher"
    When I click on "Add watcher" within "#watchers"
    And I select "Bob Bobbit" from "watcher_user_id" within "#watchers"
    And I press "Add" within "#watchers"
    Then I should see "Bob Bobbit" within "#watchers ul"
     And the issue "issue1" should have 1 watchers

  @javascript
  Scenario: Remove a watcher from an issue
    Given the issue "issue1" is watched by:
      | bob |
    When I go to the page of the issue "issue1"
    Then I should see "Bob Bobbit" within "#watchers ul"
    When I click on "Delete" within "#watchers ul"
    Then I should not see "Bob Bobbit" within "#watchers"
     And the issue "issue1" should have 0 watchers
