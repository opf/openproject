#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Creating Projects
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am already admin

  @javascript
  Scenario: Creating a Subproject
    When I go to the settings page of the project "parent"
     And I follow "New subproject"
     And I fill in "project_name" with "child"
     And I press "Save"
    Then I should be on the settings page of the project called "child"

  Scenario: Creating a Subproject
    When I go to the settings page of the project "parent"
     And I follow "New subproject"
    Then I should not see "Responsible"

  @javascript
  Scenario: Creating a Project with an already existing identifier
    When I go to the projects admin page
     And I follow "New project"
     And I fill in "project_name" with "Parent"
     And I press "Save"
    Then I should be on the projects page
     And I should see "Identifier has already been taken"
     And I fill in "project_name" with "Parent 2"
     And the "Identifier" field should contain "parent-2" within "#content"
