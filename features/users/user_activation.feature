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

Feature:User Activation

Scenario: An admin could activate the pending registration request
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123=321test"
And I fill in "user_password_confirmation" with "test123=321test"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Your account was created and is now pending administrator approval"
And I am admin
And I am on the admin page of pending users
Then I should see "heidi" within ".autoscroll"

Scenario: An admin activates the pending registration request
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123=321test"
And I fill in "user_password_confirmation" with "test123=321test"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Your account was created and is now pending administrator approval"
And I am already admin
And I am on the admin page of pending users
When I follow "Activate" within ".autoscroll"
Then I should see "Successful update"
