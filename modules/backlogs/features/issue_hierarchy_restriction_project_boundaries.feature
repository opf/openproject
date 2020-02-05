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

Feature: The work_package hierarchy between backlogs stories and backlogs tasks can not span project boundaries
  As a scrum user
  I want to limit the work_package hierarchy to not span project boundaries between backlogs stories and backlogs tasks
  So that I can manage stories more securely

  Background:
    Given there is 1 project with:
        | name       | parent_project |
        | identifier | parent_project |
    And I am working in project "parent_project"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_work_packages      |
        | add_work_packages       |
        | edit_work_packages      |
        | manage_subtasks         |
    And the backlogs module is initialized
    And the following types are configured to track stories:
        | Story |
    And the type "Task" is configured to track tasks
    And the project "parent_project" uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the type "Task" has the default workflow for the role "scrum master"
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And there is a default issuepriority with:
        | name   | Normal |
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And there is 1 project with:
        | name  | child_project  |
    And the project "child_project" uses the following modules:
        | backlogs |
    And the project "child_project" uses the following types:
        | Story |
        | Epic  |
        | Task  |
        | Bug   |
    And the user "markus" is a "scrum master" in the project "parent_project"
    And the user "markus" is a "scrum master" in the project "child_project"
    And the "cross_project_work_package_relations" setting is set to true
    And I am already logged in as "markus"
