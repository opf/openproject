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

Feature: Password Complexity Checks
    Scenario: A user changing the password including attempts to set not complex enough passwords
        Given passwords must contain 2 of lowercase, uppercase, and numeric characters
        And passwords have a minimum length of 4 characters
        And I am logged in
        And I try to set my new password to "password"
        Then there should be an error message
        When I try to set my new password to "Password"
        Then the password change should succeed
        And I should be able to login using the new password

    Scenario: An admin can change the password complexity requirements and they are effective
        Given I am already admin
        When I go to the authentication tab of the settings page
        And I activate the lowercase, uppercase, and special password rules
        And I fill in "Minimum number of required classes" with "3"
        And I save the settings
        And I try to set my new password to "adminADMIN"
        Then there should be an error message
        And I try to set my new password to "adminADMIN123"
        Then there should be an error message
        And I try to set my new password to "adminADMIN!"
        Then the password change should succeed
