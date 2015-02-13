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

Feature: Switching types of work packages
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And I am working in project "project1"
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | edit_work_packages |
      | add_work_packages  |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
    # prevent alerts to occur that would impede subsequent scenarios
    And the user "bob" has the following preferences
      | warn_on_leaving_unsaved | 0 |
    And the user "bob" is a "member" in the project "project1"
    And I am already logged in as "bob"

  @javascript
  Scenario: Previewing a new work package
    When I am on the new work_package page of the project called "project1"
     And I fill in "Description" with "pe1 description"
     And I follow "Preview"
    Then I should see "pe1 description" within "#preview"

  @javascript
  Scenario: Previewing changes on an existing work package
    Given there are the following work packages in project "project1":
      | subject  | description     |
      | pe1      | pe1 description |
    When I am on the edit page of the work package called "pe1"
     And I fill in the following:
       | Description | pe1 description changed |
       | Notes       | Update note             |
     And I follow "Preview"
    Then I should see "pe1 description changed" within "#preview"
    Then I should see "Update note" within "#preview"
