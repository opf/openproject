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

Feature: Edit story on backlogs view
  As a team member
  I want to manage story details and story priority on the scrum backlogs view
  So that I do not loose context while filling in details

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the following types are configured to track stories:
        | Story |
        | Epic  |
        | Bug   |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Bug   |
        | Task  |
    And there is 1 user with:
        | login | mathias |
    And there is a role "team member"
    And the role "team member" may have the following rights:
        | view_master_backlog   |
        | view_work_packages    |
        | edit_work_packages    |
        | add_work_packages     |
        | manage_subtasks       |
    And the user "mathias" is a "team member"
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | Sprint 001 | 2010-01-01        | 2010-01-31     |
        | Sprint 002 | 2010-02-01        | 2010-02-28     |
        | Sprint 003 | 2010-03-01        | 2010-03-31     |
        | Sprint 004 | 2010-03-01        | 2010-03-31     |
    And the project has the following owner backlogs:
        | Product Backlog |
        | Wishlist        |
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And the type "Story" has the default workflow for the role "team member"
    And there is a default issuepriority with:
        | name   | Normal |
    And the project has the following stories in the following owner backlogs:
        | subject | backlog         |
        | Story 1 | Product Backlog |
        | Story 2 | Product Backlog |
        | Story 3 | Product Backlog |
        | Story 4 | Product Backlog |
    And the project has the following stories in the following sprints:
        | subject | sprint     | story_points |
        | Story A | Sprint 001 | 10           |
        | Story B | Sprint 001 | 20           |
    And I am already logged in as "mathias"

  @javascript
  Scenario: Edit story in the backlog
    Given I am on the master backlog
     When I click on the text "Story 2"
      And I fill in "Story 2 revisited" for "subject"
      And I confirm the story form
     Then I should see 4 stories in "Product Backlog"
      And the 2nd story in the "Product Backlog" should be "Story 2 revisited"

  @javascript
  Scenario: Edit story in a sprint
    Given I am on the master backlog
     When I click on the text "Story A"
      And I fill in "Story A revisited" for "subject"
      And I fill in "11" for "story_points"
      And I confirm the story form
     Then the 1st story in the "Sprint 001" should be "Story A revisited"
      And I should see 2 stories in "Sprint 001"
      And the velocity of "Sprint 001" should be "31"
