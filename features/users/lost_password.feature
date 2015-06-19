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

Feature: Lost Password

  Background:
    Given there is 1 User with:
      | Login | johndoe |
      | Mail | johndoe@example.com |
      | Firstname | John |
      | Lastname | Doe |

  Scenario: Set a new password using lost password link
    And I am on the login page
    When I follow "t:label_password_lost" within "#login-form" [i18n]
    And I fill in "johndoe@example.com" for "Email"
    And I press "Submit"
    Then I should see "has been sent to you"
    When I use the first existing token to request a password reset
    Then I should see "New password"
    When I fill in "adminAdmin!" for "new_password"
    And I fill in "adminAdmin!" for "new_password_confirmation"
    And I click on "Save"
    Then I should see "Password was successfully updated"
    When I login as "johndoe" with password "adminAdmin!"
    Then I should be logged in as "johndoe"
