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

Feature: Backlog Settings
  As a Project Admin
  I want to configure the backlogs plugin
  So that my team and I can work effectively

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the backlogs module is initialized
    And there is 1 user with:
        | login | padme |
    And there is a role "project admin"
    And the role "project admin" may have the following rights:
        | edit_project              |
        | manage_project_activities |
    And the user "padme" is a "project admin"
    And there are the following issue status:
        | name        | is_closed  | is_default  |
        | New         | false      | true        |
        | In Progress | false      | false       |
        | Resolved    | false      | false       |
        | Closed      | true       | false       |
        | Rejected    | true       | false       |
    And I am already logged in as "padme"

  @javascript
  Scenario: One can select which status indicate that a work_package is done
    Given there is 1 project with:
        | name  | parent  |
    And I am working in project "parent"
    And the project uses the following modules:
        | backlogs |
    And I am working in project "ecookbook"
    When I go to the settings/backlogs page of the project called "ecookbook"
    Then there should be a "Resolved" field
    When I check "Resolved"
    And I press "Save"
    When I go to the settings/backlogs page of the project called "ecookbook"
    Then the "Resolved" checkbox should be checked
