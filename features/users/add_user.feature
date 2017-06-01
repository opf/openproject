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

Feature: Adding a user

  Scenario: as an admin a user can be created
    Given I am already admin
    When I go to the new user page
    And I fill in "Paul" for "user_firstname"
    And I fill in "Smith" for "user_lastname"
    And I fill in "psmith@somenet.foo" for "user_mail"
    And I submit the form by the "Create" button
    Then I should see "Successful creation"
    And I should be on the edit page of the user "psmith@somenet.foo"
    When I logout
    And I login as "psmith@somenet.foo" with password "psmithPSMITH09"
    Then I should see "Your account has not yet been activated."
