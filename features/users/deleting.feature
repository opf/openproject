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

Feature: User deletion

  @javascript
  Scenario: A user can delete himself if the setting permits it
    Given the "users_deletable_by_self" setting is set to true
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "bob"
    And I go to the my account page
    And I follow "Delete account"
    And I press "Delete"
    And I accept the alert dialog
    Then I should see "Account successfully deleted"
    And I should be on the login page

  Scenario: A user can not delete himself if the setting forbids it
    Given the "users_deletable_by_self" setting is set to false
    And there is 1 user with the following:
      | login     | bob |
    And I am already logged in as "bob"
    And I go to the my account page
    Then I should not see "Delete account" within "#main-menu"

  @javascript
  Scenario: An admin can delete other users if the setting permitts it
    Given the "users_deletable_by_admins" setting is set to true
    And there is 1 user with the following:
      | login     | bob |
    And I am already admin
    When I go to the edit page of the user "bob"
    And I click "Delete"
    And I press "Delete"
    And I accept the alert dialog
    Then I should see "Account successfully deleted"
    And I should be on the index page of users

  Scenario: An admin can not delete other users if the setting forbidds it
    Given the "users_deletable_by_admins" setting is set to false
    And there is 1 user with the following:
      | login     | bob |
    And I am already admin
    And I go to the edit page of the user "bob"
    Then I should not see "Delete" within "#toolbar"

  Scenario: Deletablilty settings can be set in the users tab of the settings
    Given I am already admin
    And the "users_deletable_by_admins" setting is set to false
    And the "users_deletable_by_self" setting is set to false
    And I go to the users tab of the settings page
    And I check "settings_users_deletable_by_admins"
    And I check "settings_users_deletable_by_self"
    And I press "Save" within "#tab-content-users"
    Then the "users_deletable_by_admins" setting should be true
    Then the "users_deletable_by_self" setting should be true
