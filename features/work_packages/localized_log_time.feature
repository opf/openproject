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

Feature: Adding localized time log
  Background:
    Given the following languages are active:
      | en |
      | de |
    And there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
      | language  | de      |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |
      | log_time           |
    And I am working in project "ecookbook"
    And the project uses the following modules:
      | time_tracking |
    And the user "manager" is a "manager"
    And there are the following status:
      | name    | default |
      | status1 | true    |
    And there are the following work packages in project "ecookbook":
      | subject | status_id |
      | pe1     | 1         |
    And there is an activity "design"
    And I am already logged in as "manager"

  @javascript
  Scenario: Adding a localized time entry with a too long topic
    Given I am on the edit page of the work package called "pe1"
    When I fill in the following:
    | Thema             | Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit |
    | Aufgewendete Zeit | 2,5    |
    | Aktivität         | design |
    And I submit the form by the "OK" button
    Then I should be on the page of the work package "pe1"
    And I should see 1 error message
    And the "work_package_time_entry_hours" field should contain "2,5"
