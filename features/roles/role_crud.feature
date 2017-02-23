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

Feature: As an admin
         I want to administrate roles with permissions
         So that I can modify permissions of roles

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Work packages can be assigned to users and groups in possession of this role in the respective project"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Successful creation."

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And there is a role "Manager"
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Work packages can be assigned to users and groups in possession of this role in the respective project"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Name has already been taken"
