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

Feature: Deleting work packages
  Background:
    Given there is 1 user with:
      | login     | manager |
    And there are the following types:
      | Name   | Is milestone |
      | Phase1 | false        |
    And there is a project named "ecookbook"
    And there is a role "manager" with the following permissions:
      | view_work_packages   |
      | delete_work_packages |
      | view_time_entries    |
      | edit_time_entries    |
    And the user "manager" is a "manager" in the project "ecookbook"
    And there are the following work packages in project "ecookbook":
      | subject |
      | wp1     |
      | wp2     |
    And there is a time entry for "wp1" with 10 hours
    And I am already logged in as "manager"

  @javascript
  Scenario: Deleting a work package via the action menu

    When I go to the page of the work package "wp1"
    And I select "Delete" from the action menu
    And I confirm popups
    Then I should be on the bulk destroy page of work packages

    When I choose "Reassign"
    And I fill in the id of work package "wp2" into "work package"
    And I submit the form by the "Apply" button

    Then I should be on the work packages index page of the project called "ecookbook"

    When I go to the page of the work package "wp2"

    Then the work package should be shown with the following values:
      | Spent time | 10.00 hours |
