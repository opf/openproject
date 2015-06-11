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

Feature: Update User Information

@javascript
Scenario: A user is able to change his mail address if the settings permit it
Given I am admin
And   I go to the my account page
And   I fill in "user_mail" with "john@doe.com"
And   I submit the form by the "Save" button
Then  I should see "Account was successfully updated."

@javascript
Scenario: A user is able to change his name if the settings permit it
Given I am admin
And   I go to the my account page
And   I fill in "user_firstname" with "Jon"
And   I fill in "user_lastname" with "Doe"
And   I submit the form by the "Save" button
Then  I should see "Account was successfully updated."
