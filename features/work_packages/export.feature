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

Feature: Exporting work packages

  Background:
    Given there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the user "bob" is a "member" in the project "project1"
    And the user "bob" has 1 issue with the following:
      | subject | Some Issue |
    And I am already logged in as "bob"

    @wip @javascript
  Scenario: No export links on project work packages index if user has no "export_work_packages" permission
    When I go to the work packages index page of the project called "project1"
    And I choose "Export" from the toolbar "settings" dropdown
    Then I should not see "CSV"
    And I should not see "PDF"

    @wip @javascript
  Scenario: Export links on project issues work packages if user has the "export_work_packages" permission
    Given the role "member" may have the following rights:
     | export_work_packages |
    When I go to the work packages index page of the project called "project1"
    And I choose "Export" from the toolbar "settings" dropdown
    Then I should see "CSV" within ".other-formats"
    And I should see "PDF" within ".other-formats"

    @wip @javascript
  Scenario: No export links on global issues index if user has no "export_work_packages" permission
    When I go to the global index page of work packages
    And I choose "Export" from the toolbar "settings" dropdown
    Then I should not see "CSV"
    And I should not see "PDF"

    @wip @javascript
  Scenario: Export links on global issues index if user has the "export_work_packages" permission
    Given the role "member" may have the following rights:
     | export_work_packages |
    When I go to the global index page of work packages
    And I choose "Export" from the toolbar "settings" dropdown
    Then I should see "CSV" within ".other-formats"
    And I should see "PDF" within ".other-formats"




