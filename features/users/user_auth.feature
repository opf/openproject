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

Feature: User Authentication
  @javascript
  Scenario: A user gets a error message if the false credentials are filled in
    Given I am logged in as "joe"
    Then I should see "Invalid user or password"

  @javascript
  Scenario: A user is able to login successfully with provided credentials
    Given I am on the login page
    And I am admin
    Then I should see "Admin" as being logged in

  @javascript
  Scenario: Lost password notification mail will not be sent in case incorrect mail is given
    Given I am on the login page
    And I open the "Openproject Admin" menu
    And I follow "t:label_password_lost" within "#login-form" [i18n]
    Then I should be on the lost password page
    And I fill in "mail" with "bilbo@shire.com"
    And I click on "Submit"
    Then I should see "Unknown user"
