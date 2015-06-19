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

Feature: Administering Project Types
  As a ChiliProject Admin
  I want to be able to do basic CRUD operations on project types

  Background:
      Given I am already admin

      And there are the following project types:
        | Name                  |
        | Standard Project      |
        | Extraordinary Project |
      And there are the following types:
        | Name           |
        | Phase          |
        | Milestone      |
        | Something else |
      And there are the following reported project statuses:
        | Name     |
        | Yeah Boy |
        | Oh Yeah  |

  Scenario: Accessing the Project Type Administration Page should yield all available project types
     When I go to the admin page
      And I follow "Project types"
     Then I should see "Standard Project"
      And I should see "Extraordinary Project"

  Scenario: Admins should be able to reach the edit page for a project type
     When I go to the admin page
      And I follow "Project types"
      And I follow the edit link of the project type "Standard Project"
     Then I should see "Standard Project"
      And I should see "Types"
      And I should see "Reported project statuses"
      And I should see "Yeah Boy"
      And I should see "Oh Yeah"

  Scenario: Admins should be able to modify the project type order
     When I go to the admin page
      And I follow "Project types"
     Then "Standard Project" should be the first element in the list
      And I move "Extraordinary Project" to the top
     Then "Extraordinary Project" should be the first element in the list
      And I should see "Successful update."
     Then I move "Extraordinary Project" down by one
     Then "Standard Project" should be the first element in the list
      And "Extraordinary Project" should be the last element in the list
      And I should see "Successful update."

  Scenario: Admins should be able to modify allows_association? through the edit form
     When I go to the admin page
      And I follow "Project types"
      And I follow "New project type"
      And I fill in "Test Type" for "Name"
      And I check "Allows association"
      And I press "Save"
     Then the "Test Type" row should be marked as allowing associations

     When I follow the edit link of the project type "Test Type"
      And I uncheck "Allows association"
      And I press "Save"
     Then the "Test Type" row should not be marked as allowing associations

  Scenario: Admins can set the reported project statuses of a project type
     When I go to the admin page
      And I follow "Project types"
      And I follow the edit link of the project type "Standard Project"
      And I check "Yeah Boy"
      And I press "Save"
     Then I should see "Successful update."
     When I follow the edit link of the project type "Standard Project"
     Then the "Yeah Boy" checkbox should be checked
     Then the "Oh Yeah" checkbox should not be checked
     When I uncheck "Yeah Boy"
      And I check "Oh Yeah"
      And I press "Save"
     Then I should see "Successful update."
     When I follow the edit link of the project type "Standard Project"
     Then the "Yeah Boy" checkbox should not be checked
      And the "Oh Yeah" checkbox should be checked

  Scenario: Admins can create new project types JUST LIKE THAT
     When I go to the admin page
      And I follow "Project types"
      And I follow "New project type"
      And I fill in "Name" with "Another Project Type"
      And I check "Yeah Boy"
      And I press "Save"
     Then I should see "Successful creation."
      And "Another Project Type" should be the last element in the list

  Scenario: Nice error messages on create to help fixing them
     When I go to the admin page
      And I follow "Project types"
      And I follow "New project type"
      And I fill in "" for "Name"
      And I press "Save"
      And I should see an error explanation stating "Name can't be blank"

     When I fill in "Some other Project" for "Name"
      And I press "Save"
     Then I should see a notice flash stating "Successful creation."
      And I should see "Some other Project"

  Scenario: Nice error messages on update to help fixing them
     When I go to the admin page
      And I follow "Project types"
      And I follow the edit link of the project type "Extraordinary Project"
      And I fill in "" for "Name"
      And I press "Save"
     Then I should see an error explanation stating "Name can't be blank"

     When I fill in "Super-Extraordinary Project" for "Name"
      And I press "Save"
     Then I should see a notice flash stating "Successful update."
      And I should see "Super-Extraordinary Project"

  Scenario: Admins are able to delete project types
     When I go to the admin page
      And I follow "Project types"
      And I follow "Delete Extraordinary Project"
      And I press "Delete"

     Then I should see a notice flash stating "Successful deletion."
      And I should not see "Extraordinary Project"
