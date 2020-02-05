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

Feature: Product Owner
  As a product owner
  I want to manage story details and story priority
  So that they get done according to my requirements

  Background:
    Given the following types are configured to track stories:
          | Story |
          | Epic  |
      And the type "Task" is configured to track tasks
      And there are the following issue status:
          | name        | is_closed  | is_default  |
          | New         | false      | true        |
          | Closed      | true       | false       |

      And there is a role "product owner"
      And the role "product owner" may have the following rights:
          | view_master_backlog   |
          | view_work_packages    |
          | add_work_packages     |
          | edit_work_packages    |
          | manage_subtasks       |
          | assign_versions       |

      And the type "Story" has the default workflow for the role "product owner"
      And the type "Epic" has the default workflow for the role "product owner"
      And the type "Task" has the default workflow for the role "product owner"

      And there is 1 project with:
          | name  | ecookbook |
      And I am working in project "ecookbook"
      And there is a default issuepriority with:
          | name   | Normal |
      And the project uses the following modules:
          | backlogs |
      And the project uses the following types:
          | Story |
          | Epic  |
          | Task  |

      And there is 1 user with:
          | login | mathias |
      And the user "mathias" is a "product owner"

      And the project has the following sprints:
          | name       | start_date | effective_date |
          | Sprint 001 | 2010-01-01        | 2010-01-31     |
          | Sprint 002 | 2010-02-01        | 2010-02-28     |
          | Sprint 003 | 2010-03-01        | 2010-03-31     |
          | Sprint 004 | 2010-03-01        | 2010-03-31     |
      And the project has the following product owner backlogs:
          | Product Backlog |
          | Wishlist        |
      And the project has the following stories in the following product owner backlogs:
          | subject | backlog         |
          | Story 1 | Product Backlog |
          | Story 2 | Product Backlog |
          | Story 3 | Product Backlog |
          | Story 4 | Product Backlog |
      And the project has the following stories in the following sprints:
          | subject | sprint     |
          | Story A | Sprint 001 |
          | Story B | Sprint 001 |
      And I am already logged in as "mathias"

  Scenario: View the product backlog
     When I go to the master backlog
     Then I should see the product backlog
      And I should see 4 stories in the "Product Backlog"
      And I should see 4 sprint backlogs
      And I should see 2 product owner backlogs

  Scenario: Create a new story
     When I go to the master backlog
      And I want to create a story
      And I set the backlog of the story to Product Backlog
      And I set the subject of the story to A Whole New Story
      And I create the story
     Then the 1st story in the "Product Backlog" should be "A Whole New Story"
      And all positions should be unique for each version

  Scenario: Update a story
    Given I am on the master backlog
      And I want to edit the story with subject Story 3
      And I set the subject of the story to Relaxdiego was here
      And I set the type of the story to Epic
     When I update the story
     Then the story should have a subject of Relaxdiego was here
      And the story should have a type of Epic
      And the story should be at position 3

  Scenario: Close a story
    Given I am on the master backlog
      And I want to edit the story with subject Story 4
      And I set the status of the story to Closed
     When I update the story
     Then the status of the story should be set as closed

  Scenario: Move a story to the top
    Given I am on the master backlog
     When I move the 3rd story to the 1st position
     Then the 1st story in the "Product Backlog" should be "Story 3"

  Scenario: Move a story to the bottom
    Given I am on the master backlog
     When I move the 2nd story to the last position
     Then the 4th story in the "Product Backlog" should be "Story 2"

  Scenario: Move a story down
    Given I am on the master backlog
     When I move the 2nd story to the 3rd position
     Then the 2nd story in the "Product Backlog" should be "Story 3"
      And the 3rd story in the "Product Backlog" should be "Story 2"
      And the 4th story in the "Product Backlog" should be "Story 4"

  Scenario: Move a story up
    Given I am on the master backlog
     When I move the 4th story to the 2nd position
     Then the 2nd story in the "Product Backlog" should be "Story 4"
      And the 3rd story in the "Product Backlog" should be "Story 2"
      And the 4th story in the "Product Backlog" should be "Story 3"
