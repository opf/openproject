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

Feature: The work_package hierarchy defines the allowed versions for each work_package dependent on the type
  As a team member
  I want to CRUD work_packages with a reliable target version system
  So that I know what target version an work_package can have or will be assigned

  Background:
    Given there is 1 project with:
        | name       | ecookbook |
        | identifier | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | update_sprints          |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_work_packages      |
        | edit_work_packages      |
        | manage_subtasks         |
        | add_work_packages       |
        | assign_versions         |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is a default issuepriority with:
        | name   | Normal |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the type "Task" has the default workflow for the role "scrum master"
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And the user "markus" is a "scrum master"
    And the project has the following sprints:
        | name       | start_date | effective_date  |
        | Sprint 001 | 2010-01-01        | 2010-01-31      |
        | Sprint 002 | 2010-02-01        | 2010-02-28      |
        | Sprint 003 | 2010-03-01        | 2010-03-31      |
        | Sprint 004 | 2.weeks.ago       | 1.week.from_now |
        | Sprint 005 | 3.weeks.ago       | 2.weeks.from_now|
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
        | Story B | Sprint 001 |
        | Story C | Sprint 002 |
    And I am already logged in as "markus"

  @javascript
  Scenario: Creating a task, via the taskboard, as a subtask to a story sets the target version to the story´s version
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task 0815" for "subject"
      And I press "OK"
     Then I should see "Task 0815" as a task to story "Story A"
      And the request on task "Task 0815" is finished
      And the task "Task 0815" should have "Sprint 001" as its target version

  @javascript
  Scenario: Stale Object Error when creating task via the taskboard without 'Remaining Hours' after having created a task with 'Remaining Hours' after having created a task without 'Remaining Hours' (bug 9057)
    Given I am on the taskboard for "Sprint 001"
     When I click to add a new task for story "Story A"
      And I fill in "Task1" for "subject"
      And I fill in "3" for "remaining hours"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task2" for "subject"
      And I press "OK"
      And I click to add a new task for story "Story A"
      And I fill in "Task3" for "subject"
      And I fill in "7" for "remaining hours"
      And I press "OK"
      And the request on task "Task1" is finished
      And the request on task "Task2" is finished
      And the request on task "Task3" is finished
     Then there should not be a saving error on task "Task3"
      And the task "Task1" should have "Sprint 001" as its target version
      And the task "Task2" should have "Sprint 001" as its target version
      And the task "Task3" should have "Sprint 001" as its target version
      And task Task1 should have remaining_hours set to 3
      And task Task3 should have remaining_hours set to 7
