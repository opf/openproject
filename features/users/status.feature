#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

Feature: User Status
  Background:
    Given I am already admin
    Given there is a user named "bobby"

  @javascript
  Scenario: Users can be filtered by status
    # had to append the 'within ".list tbody"' in order to avoid the "I should
    # (not) see "admin"' step to find the "OpenProject Admin" string for the
    # logged in user as well as the "Administrator" string in the table header.
    Given the user "bobby" had too many recently failed logins
    And I filter the users list by status "active (1)"
    Then I should not see "bobby" within ".generic-table tbody"
    And I should see "admin" within ".generic-table tbody"
    And I should not see "Anonymous" within ".generic-table tbody"
    And I filter the users list by status "locked temporarily (1)"
    Then I should see "bobby" within ".generic-table tbody"
    And I should not see "admin" within ".generic-table tbody"
    And I should not see "Anonymous" within ".generic-table tbody"
    When the user "bobby" is locked
    And I filter the users list by status "locked permanently (1)"
    Then I should see "bobby" within ".generic-table tbody"
    And I should not see "admin" within ".generic-table tbody"
    And I should not see "Anonymous" within ".generic-table tbody"
    And I filter the users list by status "locked temporarily (1)"
    Then I should see "bobby" within ".generic-table tbody"
    And I should not see "admin" within ".generic-table tbody"
    And I should not see "Anonymous" within ".generic-table tbody"
    And I filter the users list by status "all (2)"
    Then I should see "bobby" within ".generic-table tbody"
    And I should see "admin" within ".generic-table tbody"
    And I should not see "Anonymous" within ".generic-table tbody"

  @javascript
  Scenario: User can be unlocked on the index page
    Given the user "bobby" is locked
    When I filter the users list by status "locked permanently (1)"
    And I click "Unlock"
    Then I should not see "bobby"
    And I try to log in with user "bobby"
    Then I should see "Bob Bobbit" as being logged in

  Scenario: A locked and blocked user gets unlocked and unblocked
    Given the user "bobby" is locked
    And the user "bobby" had too many recently failed logins
    When I edit the user "bobby"
    And I click "Unlock and reset failed logins"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit" as being logged in

  Scenario: An active user gets locked
    When I edit the user "bobby"
    And I click "Lock permanently"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit" as being logged in

  Scenario: A registered user gets activated
    Given the user "bobby" is registered and not activated
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I am already admin
    And I edit the user "bobby"
    And I click "Activate"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit" as being logged in
