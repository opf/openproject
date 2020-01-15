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

Feature: Scrum Master
  As a scrum master
  I want to manage sprints and their stories
  So that they get done according the product owner´s requirements

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | update_sprints          |
        | add_work_packages       |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_work_packages      |
        | edit_work_packages      |
        | manage_subtasks         |
        | assign_versions         |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is a default issuepriority with:
        | name   | Normal |
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
    And the project has the following product owner backlogs:
        | Product Backlog |
        | Wishlist        |
    And the project has the following stories in the following backlogs:
        | subject | backlog |
        | Story 1 | Product Backlog |
        | Story 2 | Product Backlog |
        | Story 3 | Product Backlog |
        | Story 4 | Product Backlog |
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
        | Story B | Sprint 001 |
        | Story C | Sprint 002 |
    And the project has the following tasks:
        | subject      | sprint     | parent     |
        | Task 1       | Sprint 001 | Story A    |
    And the project has the following impediments:
        | subject      | sprint     | blocks     |
        | Impediment 1 | Sprint 001 | Story A    |
    And the project has the following work_packages:
        | subject      | sprint     | type    |
        | Epic 1       | Sprint 005 | Epic       |
    And the project has the following stories in the following sprints:
        | subject      | sprint     | parent     |
        | Story D      | Sprint 005 | Epic 1     |
        | Story E      | Sprint 005 | Epic 1     |
    And the project has the following tasks:
        | subject      | sprint     | parent     |
        | Task 10      | Sprint 005 | Story D    |
        | Task 11      | Sprint 005 | Story D    |
        | Subtask 1    | Sprint 005 | Task 10    |
        | Subtask 2    | Sprint 005 | Task 10    |
        | Subtask 3    | Sprint 005 | Task 11    |
    And the project has the following work_packages:
        | subject      | sprint     | parent     | type    |
        | Subfeature   | Sprint 005 | Task 10    | Bug        |
        | Subsubtask   | Sprint 005 | Subfeature | Task       |
    And I am already logged in as "markus"

  Scenario: View stories that have a parent ticket
   Given I am on the master backlog
    Then I should see 2 stories in "Sprint 005"
     And I should not see "Epic 1"
     And I should not see "Task 10"
     And I should not see "Subtask 1"
     And I should not see "Subfeature"

  @javascript
  Scenario: Create an impediment
    Given I am on the taskboard for "Sprint 001"
    When I click on the element with class "add_new" within "#impediments"
    And I fill in "Bad Company" for "subject"
    And I fill in the ids of the tasks "Task 1" for "blocks_ids"
    And I select "Markus Master" from "assigned_to_id"
    And I press "OK"
    And the impediment "Bad Company" should signal successful saving
    Then I should see "Bad Company" within "#impediments"

  @javascript
  Scenario: Create an impediment blocking an work_package of another sprint
    Given I am on the taskboard for "Sprint 001"
    When I click on the element with class "add_new" within "#impediments"
    And I fill in "Bad Company" for "subject"
    And I fill in the ids of the stories "Story C" for "blocks_ids"
    And I select "Markus Master" from "assigned_to_id"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages can only contain IDs of work packages in the current sprint."

  @javascript
  Scenario: Create an impediment blocking a non existent work_package
    Given I am on the taskboard for "Sprint 001"
    When I click on the element with class "add_new" within "#impediments"
    And I fill in "Bad Company" for "subject"
    And I fill in "0" for "blocks_ids"
    And I select "Markus Master" from "assigned_to_id"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages can only contain IDs of work packages in the current sprint."

  @javascript
  Scenario: Create an impediment without specifying what it blocks
    Given I am on the taskboard for "Sprint 001"
    When I click on the element with class "add_new" within "#impediments"
    And I fill in "Bad Company" for "subject"
    And I fill in "" for "blocks_ids"
    And I select "Markus Master" from "assigned_to_id"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages must contain the ID of at least one ticket"

  @javascript
  Scenario: Update an impediment
    Given I am on the taskboard for "Sprint 001"
    When I click on the impediment called "Impediment 1"
    And I fill in "Bad Company" for "subject"
    And I fill in the ids of the tasks "Task 1" for "blocks_ids"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal successful saving

  @javascript
  Scenario: Update an impediment to block an work_package of another sprint
    Given I am on the taskboard for "Sprint 001"
    When I click on the impediment called "Impediment 1"
    And I fill in "Bad Company" for "subject"
    And I fill in the ids of the stories "Story C" for "blocks_ids"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages can only contain IDs of work packages in the current sprint."

  @javascript
  Scenario: Update an impediment to block a non existent work_package
    Given I am on the taskboard for "Sprint 001"
    When I click on the impediment called "Impediment 1"
    And I fill in "Bad Company" for "subject"
    And I fill in "0" for "blocks_ids"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages can only contain IDs of work packages in the current sprint."

  @javascript
  Scenario: Update an impediment to not block anything
    Given I am on the taskboard for "Sprint 001"
    When I click on the impediment called "Impediment 1"
    And I fill in "Bad Company" for "subject"
    And I fill in "" for "blocks_ids"
    And I press "OK"
    Then I should see "Bad Company" within "#impediments"
    And the impediment "Bad Company" should signal unsuccessful saving
    And the error alert should show "IDs of blocked work packages must contain the ID of at least one ticket"

  Scenario: Update sprint details
    Given I am on the master backlog
      And I want to edit the sprint named Sprint 001
      And I want to set the name of the sprint to sprint xxx
      And I want to set the start_date of the sprint to 2010-03-01
      And I want to set the effective_date of the sprint to 2010-03-20
     When I update the sprint
     Then the request should complete successfully
      And the sprint should be updated accordingly

  Scenario: Update sprint with no name
    Given I am on the master backlog
      And I want to edit the sprint named Sprint 001
      And I want to set the name of the sprint to an empty string
     When I update the sprint
     Then the server should return an update error

  Scenario: Move a story from product backlog to sprint backlog
    Given I am on the master backlog
     When I move the story named Story 1 up to the 1st position of the sprint named Sprint 001
     Then the request should complete successfully
     When I move the story named Story 4 up to the 2nd position of the sprint named Sprint 001
      And I move the story named Story 2 up to the 1st position of the sprint named Sprint 002
      And I move the story named Story 4 up to the 1st position of the sprint named Sprint 001
     Then Story 4 should be in the 1st position of the sprint named Sprint 001
      And Story 1 should be in the 2nd position of the sprint named Sprint 001
      And Story 2 should be in the 1st position of the sprint named Sprint 002

  Scenario: Move a story down in a sprint
    Given I am on the master backlog
     When I move the story named Story A below Story B
     Then the request should complete successfully
      And Story A should be in the 2nd position of the sprint named Sprint 001
      And Story B should be the higher item of Story A

  Scenario: View tasks that have subtasks
  Given I am on the taskboard for "Sprint 005"
   Then I should see "Task 10" within "#tasks"
    And I should see "Task 11" within "#tasks"
    And I should not see "Subtask 1"
    And I should not see "Subtask 2"
    And I should not see "Subtask 3"
    And I should not see "Epic 1"
    And I should not see "Subfeature"
    And I should not see "Subsubtask"

  Scenario: Move stories around in the backlog that have a parent ticket
   Given I am on the master backlog
    When I move the story named Story D below Story E
    Then the request should complete successfully
     And Story D should be in the 2nd position of the sprint named Sprint 005
     And Story E should be the higher item of Story D

  @javascript
  Scenario: View epic, stories, tasks, subtasks in the work_package list
    When I go to the work_packages index page
    Then I should see "Epic 1" within ".work-package-table--container table"
     And I should see "Story D" within ".work-package-table--container table"
     And I should see "Story E" within ".work-package-table--container table"
     And I should see "Task 10" within ".work-package-table--container table"
     And I should see "Task 11" within ".work-package-table--container table"
     And I should see "Subtask 1" within ".work-package-table--container table"
     And I should see "Subtask 2" within ".work-package-table--container table"
     And I should see "Subtask 3" within ".work-package-table--container table"
     And I should see "Subfeature" within ".work-package-table--container table"
     And I should see "Subsubtask" within ".work-package-table--container table"

  Scenario: Move a task with subtasks around in the taskboard
   Given I am on the taskboard for "Sprint 005"
    When I move the task named Task 10 below Task 11
    Then the request should complete successfully
     And Task 11 should be the higher task of Task 10
     And the story named Story D should have 1 task named Task 10
     And the story named Story D should have 1 task named Task 11
