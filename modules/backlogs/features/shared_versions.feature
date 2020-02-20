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

Feature: Shared Versions
  As a Team Members
  I want to use versions shared by other projects
  So that I can distribute work efficiently

  Background:
    Given there is 1 project with:
        | name  | parent    |
    And the project "parent" has the following sprints:
        | name          | sharing     | start_date | effective_date |
        | ParentSprint  | system      | 2010-01-01 | 2010-01-31     |
    And there is 1 project with:
        | name  | child |
    And the project "child" uses the following modules:
        | backlogs |
    And the following types are configured to track stories:
        | story |
        | epic  |
    And the type "task" is configured to track tasks
    And the project "parent" uses the following types:
        | story |
        | task  |
    And the project "child" uses the following types:
        | story |
        | task  |
    And I am working in project "child"
    And there is a default status with:
        | name | new |
    And there is a default issuepriority with:
        | name   | Normal |
    And there is 1 user with:
        | login | padme |
    And there is a role "project admin"
    And the role "project admin" may have the following rights:
        | manage_versions     |
        | view_work_packages  |
        | view_master_backlog |
        | add_work_packages   |
        | edit_work_packages  |
        | manage_subtasks     |
    And the user "padme" is a "project admin"
    And the project has the following sprints:
        | name        | start_date | effective_date |
        | ChildSprint | 2010-03-01 | 2010-03-31     |
    And I am already logged in as "padme"

  Scenario: Inherited Sprints are displayed
    Given I am on the master backlog
    Then I should see "ParentSprint" within "#sprint_backlogs_container .backlog:first-child .sprint .name"

  Scenario: Only stories of current project are displayed
    Given the project "parent" has the following stories in the following sprints:
      | subject        | backlog        |
      | ParentStory    | ParentSprint   |
    And the project "child" has the following stories in the following sprints:
      | subject        | backlog        |
      | ChildStory     | ParentSprint   |
    And I am on the master backlog
    Then I should see "ChildStory" within ".backlog .story .subject"
    And I should not see "ParentStory" within ".backlog .story .subject"
