#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: General Reporting administration
  As a ChiliProject Admin
  I want to perform CRUD operations on reportings.

  Background:
    Given I am already admin

    Given there is 1 project with the following:
          | Name | Santas Project                      |
    Given there is 1 project with the following:
          | Name | World Domination                    |
    Given there is 1 project with the following:
          | Name | How to stay sane and drink lemonade |
    And there is a timeline "Testline" for project "Santas Project"
    And there is a timeline "Testline" for project "World Domination"
    And there is a timeline "Testline" for project "How to stay sane and drink lemonade"

  @javascript
  Scenario: Creating a reporting
     When I go to the reportings of the project called "Santas Project"
      And I click on "New reporting"
      And I should see "Reports to project"

     When I select "World Domination" from "Reports to project"
      And I press "Create" within "#content"
     Then I should see "Successful creation."
      And I should see "World Domination"

  @javascript
  Scenario: Creating a reporting when there is a reporting already present
    Given there are the following reportings:
          | Project        | Reporting To Project | Reported Project Status Comment |
          | Santas Project | World Domination     | Hallo Junge                     |
     When I go to the reportings of the project called "Santas Project"
      And I click on "New reporting"
      And I should see "Reports to project"

     When I select "How to stay sane and drink lemonade" from "Reports to project"
      And I press "Create" within "#content"
     Then I should see "Successful creation."
      And I should see "World Domination"
      And I should see "How to stay sane and drink lemonade"

  Scenario: Editing a reporting
    Given there are the following reportings:
          | Project        | Reporting To Project | Reported Project Status Comment |
          | Santas Project | World Domination     | Hallo Junge                     |
     When I go to the reportings of the project called "Santas Project"
     Then I should see "World Domination"
      And I should see "Hallo Junge"

     When I follow link "Edit" for report "World Domination"
     Then I should see "Status comment"
      And I should see "Project status"

     When I fill in "So'n Feuerball" for "Status comment"
      And I click on "Save"
     Then I should see "Successful update."
      And I should see "So'n Feuerball"

  Scenario: Editing a reporting with another reporting present
    Given there is 1 project with the following:
          | Name | Careful Boy |
      And there are the following reportings:
          | Project        | Reporting To Project | Reported Project Status Comment |
          | Santas Project | World Domination     | Hallo Junge                     |
          | Santas Project | Careful Boy          | Don't be a-gamblin'             |

     When I go to the reportings of the project called "Santas Project"
     Then I should see "World Domination"
      And I should see "Hallo Junge"
      And I should see "Careful Boy"
      And I should see "Don't be a-gamblin'"

     When I follow link "Edit" for report "Careful Boy"
      And I fill in "So'n Feuerball" for "Status comment"
      And I click on "Save"

     Then I should see "Successful update."
      And I should see "Careful Boy"
      And I should see "So'n Feuerball"
      And I should see "World Domination"
      And I should see "Hallo Junge"

  Scenario: Deleting a reporting with another reporting present
    Given there are the following reportings:
          | Project        | Reporting To Project | Reported Project Status Comment |
          | Santas Project | World Domination     | Hallo Junge                     |
     When I go to the reportings of the project called "Santas Project"
     When I follow link "Delete" for report "World Domination"
      And I click on "Delete"

     Then I should see "Successful deletion."
      And I should not see "World Domination"
      And I should not see "Hallo Junge"

  Scenario: Not confirming Delete
    Given there are the following reportings:
          | Project        | Reporting To Project | Reported Project Status Comment |
          | Santas Project | World Domination     | Hallo Junge                     |
     When I go to the reportings of the project called "Santas Project"
      And I click on "Delete"
      And I click on "Cancel"

     Then I should not see "Successful deletion."
      And I should see "World Domination"
      And I should see "Hallo Junge"
