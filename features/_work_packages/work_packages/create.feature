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

Feature: Creating work packages
  Background:
    Given there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
    And there are the following types:
      | Name   | Is milestone |
      | Phase1 | false        |
      | Phase2 | false        |
    And there are the following project types:
      | Name                  |
      | Standard Project      |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And the project named "ecookbook" is of the type "Standard Project"
    And the following types are enabled for projects of type "Standard Project"
      | Phase1 |
      | Phase2 |
    And I am working in project "ecookbook"
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | add_work_packages    |
      | create_work_packages |
      | edit_work_packages   |
      | view_work_packages   |
      | manage_subtasks      |
    And the user "manager" is a "manager" in the project "ecookbook"
    And there are the following priorities:
      | name  | default |
      | prio1 | true    |
      | prio2 |         |
    And there are the following status:
      | name    | default |
      | status1 | true    |
      | status2 |         |
    And the type "Phase1" has the default workflow for the role "manager"
    And the type "Phase2" has the default workflow for the role "manager"
    And I am already logged in as "manager"

  Scenario: Creating a new work package without required fields should give an error-message
    When I go to the new work_package page of the project called "ecookbook"
    And I submit the form by the "Create" button
    Then I should see "Subject can't be blank" within "#errorExplanation"
