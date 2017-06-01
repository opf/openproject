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

Feature: Pasword expiry
  Background:
    Given there is a user named "bob"
    And I am already admin

  Scenario: An admin activating password expiry forces a user to change the password
    When I set passwords to expire after 30 days
    # login should succeed
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit" as being logged in
    When the time is 31 days later
    # 31 days later, the login should fail
    And I try to log in with user "bob"
    Then I should not see "Bob Bobbit" as being logged in
    And there should be a flash error message
    # After changing the password, the user should be logged in
    When I fill out the change password form
    Then there should be a flash notice message
    And I should see "Bob Bobbit" as being logged in

  Scenario: An admin deactivating password expiry allows a user to login
    When I set passwords to expire after 0 days
    # login should succeed
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit" as being logged in
    When the time is 31 days later
    # 31 days later, the login should fail
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit" as being logged in
