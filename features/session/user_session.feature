#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

Feature: User session
  Background:
    Given there is 1 user with the following:
      | login    | bob        |

  Scenario: A user will be forwarded to the login page from the my page
    When I go to the My page
    Then I should be on the login page
    When I fill in "bob" for "username" within "#login-form"
    And I fill in "adminADMIN!" for "password" within "#login-form"
    And I click on "t:button_login" within "#login-form" [i18n]
    And I go to the my account page
    Then I should be on the my account page

  Scenario: A user logging in will be forwarded to the original page
    When I go to the my account page
    Then I should be on the login page
    When I fill in "bob" for "username" within "#login-form"
    And I fill in "adminADMIN!" for "password" within "#login-form"
    And I click on "t:button_login" within "#login-form" [i18n]
    Then I should be on the my account page

  Scenario: Autologin works if enabled
    Given the "autologin" setting is set to 1
    Given the "session_ttl_enabled" setting is set to true
    And the "session_ttl" setting is set to 5
    When I login with autologin enabled as "bob"
    And I wait for "10" minutes
    And I go to the home page
    Then I should be logged in as "bob"

  Scenario: Autologin does not work if disabled
    Given the "autologin" setting is set to 0
    Given the "session_ttl_enabled" setting is set to true
    And the "session_ttl" setting is set to 5
    When I login with autologin enabled as "bob"
    And I wait for "10" minutes
    And I go to the home page
    Then I should be logged out

  Scenario: A user can log out
    Given I am logged in as "bob"
    When I logout
    Then I should be logged out

  Scenario: A blocked user cannot log in
    Given there is 1 user with the following:
      | login                 | blocked_user |
      | password              | iamblocked   |
      | password_confirmation | iamblocked   |
    And the user "blocked_user" is locked
    When I login as blocked_user with password iamblocked
    Then there should be a flash error message
    And the flash message should contain "Invalid user or password"

