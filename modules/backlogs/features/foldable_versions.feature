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

Feature: Foldable versions in master backlog

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
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_work_packages      |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Task  |
    And there is a default status with:
        | name | new |
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
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
        | Story B | Sprint 001 |
        | Story C | Sprint 001 |
    And I am already logged in as "markus"

  @javascript
  Scenario: Version are not folded by default and can be folded
    When I go to the master backlog
    Then I should see "Story A" within ".backlog"

    When I change the fold state of a version
    Then I should not see "Story A" within ".backlog"

  @javascript
  Scenario: Version fold status depends on users setting
    When I go to the my settings page
     And I check "Show versions folded"
     And I submit the form by the "Save" button
    Then I should see "Account was successfully updated"

    When I go to the master backlog
    Then I should not see "Story A" within ".backlog"

    When I change the fold state of a version
    Then I should see "Story A" within ".backlog"

    Then I go to the my settings page
     And I uncheck "Show versions folded"
     And I submit the form by the "Save" button
    Then I should see "Account was successfully updated"

    When I go to the master backlog
    Then I should see "Story A" within ".backlog"

    When I change the fold state of a version
    Then I should not see "Story A" within ".backlog"
