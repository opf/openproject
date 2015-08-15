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

Feature: User Status
  Background:
    Given I am already admin
    Given there is a user named "bobby"

  Scenario: Existing user can be assigned a random password
    When I assign the user "bobby" a random password
    Then an e-mail should be sent containing "Password"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bobby" and the password sent via email
    Then there should be a flash error message
    And there should be a "New password" field

  @javascript
  Scenario: New user can be assigned a random password
    When I create a new user
    And I check the assign random password to user field
    And I save the new user
    Then an e-mail should be sent containing "Password"
    When I try to log in with user "newbobby"
    Then I should not see "Bob Bobbit"
    When I try to log in with user "newbobby" and the password sent via email
    Then there should be a flash error message
    And there should be a "New password" field

  @javascript
  Scenario: Password fields are disabled and cleared when random password assignment is activated
    When I edit the user "bobby"
    And I check the assign random password to user field
    Then the password and confirmation fields should be empty
    And the password and confirmation fields should be disabled
    And the force password change field should be checked
    And the force password change field should be disabled
    When I click "Save"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
