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

Feature: User Registration

@javascript
Scenario: A user can register successfully after filling in the registration form
Given I open the registration modal
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@test.com"
And I click on "Create" within ".registration-modal"
Then I should see "Your account was created and is now pending administrator approval."

@javascript
Scenario: A user is unable to register if one of the constraints left blank
Given I open the registration modal
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I click on "Create" within ".registration-modal"
Then the element "#user_mail" should be invalid

@javascript
Scenario: A user is unable to register if the password does not match the confirmation
Given I open the registration modal
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test1"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@test.com"
And I click on "Create" within ".registration-modal"
Then I should see "Confirmation doesn't match Password"
