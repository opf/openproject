#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

Feature: Team Member
  As a team member
  I want to manage update stories and tasks
  So that I can update everyone on the status of the project

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the following types are configured to track stories:
        | Story |
        | Epic  |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Task  |
    And there is a default status with:
        | name | new |
    And there is a default issuepriority with:
        | name   | Normal |
    And there is 1 user with:
        | login | paul |
    And there is a role "team member"
    And the role "team member" may have the following rights:
        | view_master_backlog |
        | view_taskboards     |
        | view_work_packages  |
        | edit_work_packages  |
        | manage_subtasks     |
        | add_work_packages   |
        | assign_versions     |
    And the user "paul" is a "team member"
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | Sprint 001 | 2010-01-01 | 2010-01-31     |
        | Sprint 002 | 2010-02-01 | 2010-02-28     |
        | Sprint 003 | 2010-03-01 | 2010-03-31     |
        | Sprint 004 | 2010-03-01 | 2010-03-31     |
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story 1 | Sprint 001 |
        | Story 2 | Sprint 001 |
        | Story 3 | Sprint 001 |
        | Story 4 | Sprint 002 |
    And the project has the following tasks:
        | subject | parent  |
        | Task 1  | Story 1 |
    And the project has the following impediments:
        | subject      | sprint     | blocks  |
        | Impediment 1 | Sprint 001 | Story 1 |
        | Impediment 2 | Sprint 001 | Story 2 |
    And I am already logged in as "paul"

  Scenario: Create a task for a story
    Given I am on the taskboard for "Sprint 001"
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
     When I create the task
     Then the request should complete successfully
      And the 1st task for Story 1 should be A Whole New Task

  Scenario: Update a task for a story
    Given I am on the taskboard for "Sprint 001"
      And I want to edit the task named Task 1
      And I set the subject of the task to Whoa there, Sparky
     When I update the task
     Then the request should complete successfully
      And the story named Story 1 should have 1 task named Whoa there, Sparky

  Scenario: View a taskboard
    Given I am on the taskboard for "Sprint 001"
     Then I should see the taskboard

  @javascript
  Scenario: View the burndown chart from the backlogs dashboard
    Given I am on the master backlog
      And I open the "Sprint 002" backlogs menu
     Then I should see "Burndown Chart"

  @javascript
  Scenario: View the burndown chart from the taskboard
    Given I am on the taskboard for "Sprint 002"
     Then I should see "Burndown Chart"

 @javascript
  Scenario: View sprint stories in the work_packages tab
    Given I am on the master backlog
     When I view the stories of Sprint 001 in the work_packages tab
     Then I should be on the work packages index page of the project called "ecookbook"
     When I press "Filter"
     Then I should see "Sprint 001" within "#values-version"

  @javascript
  Scenario: View the project stories in the work_packages tab
    Given I am on the master backlog
     When I view the stories in the work_packages tab
     Then I should be on the work packages index page of the project called "ecookbook"
     When I press "Filter"
     Then I should see "Version" within "#filters"

  Scenario: Copy estimate to remaining
    Given I am on the taskboard for "Sprint 001"
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the estimated_hours of the task to 3
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have remaining_hours set to 3

  Scenario: Copy remaining to estimate
    Given I am on the taskboard for "Sprint 001"
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the remaining_hours of the task to 3
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have estimated_hours set to 3

  Scenario: Set both estimate and remaining
    Given I am on the taskboard for "Sprint 001"
      And I want to create a task for Story 1
      And I set the subject of the task to A Whole New Task
      And I set the remaining_hours of the task to 3
      And I set the estimated_hours of the task to 8
     When I create the task
      And I want to create a task for Story 1
      And I set the subject of the task to A Second New Task
      And I set the remaining_hours of the task to 1
      And I set the estimated_hours of the task to 2
     When I create the task
     Then the request should complete successfully
      And task A Whole New Task should have remaining_hours set to 3
      And task A Whole New Task should have estimated_hours set to 8
      And story Story 1 should have remaining_hours set to 4
      And story Story 1 should have derived_estimated_hours set to 10
