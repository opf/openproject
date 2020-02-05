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

Feature: Export sprint stories as PDF on the Backlogs view
  As a team member
  I want to export stories as a PDF on the scrum backlogs view
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
    And the project has the following stories in the following sprints:
        | subject | sprint     | story_points |
        | Story A | Sprint 001 | 10           |
        | Story B | Sprint 001 | 20           |
    And I am already logged in as "mathias"

  @javascript
  Scenario: Export sprint stories as a PDF using the default configuration
    Given there is the single default export card configuration
    And I am on the master backlog
    When I open the "Sprint 001" backlogs menu
    And I follow "Export" of the "Sprint 001" backlogs menu
    Then the PDF download dialog should be displayed
