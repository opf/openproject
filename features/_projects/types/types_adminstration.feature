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

Feature: Type Administration
  As an OpenProject Admin
  I want to configure which types are available
  So that I can support my teams with useful settings while still controlling
  the total number of available types
  So that my teams can work effectively

  Background:
    Given there are the following types:
          | Name            | Is Milestone | In aggregation | Is Standard |
          | Phase           | false        | true           | false       |
          | Milestone       | true         | true           | false       |
          | Minor Phase     | false        | false          | false       |
          | Minor Milestone | true         | false          | false       |
          | Standard        | true         | false          | true        |
      And I am already admin

  Scenario: The admin may see all types within the admin UI
     When I go to the global index page of types
     Then I should see that "Phase" is not a milestone and shown in aggregation
      And I should see that "Milestone" is a milestone and shown in aggregation
      And I should see that "Minor Phase" is not a milestone and not shown in aggregation
      And I should see that "Minor Milestone" is a milestone and not shown in aggregation

  Scenario: The admin may create a type
     When I go to the global index page of types
      And I follow "New type"
      And I fill in "New Phase" for "Name"
      And I press "Create"
     Then I should see a notice flash stating "Successful creation."
      And I should see that "New Phase" is not a milestone and shown in aggregation
      And "New Phase" should be the last element in the list

  Scenario: Nice error messages help fixing them
     When I go to the global index page of types
      And I follow "New type"
      And I fill in "" for "Name"
      And I press "Create"
     Then I should see an error explanation stating "Name can't be blank"

  Scenario: The admin may edit a type
     When I go to the edit page of the type called "Phase"
      And I fill in "Updated Phase" for "Name"
      And I press "Save"
     Then I should see a notice flash stating "Successful update."
      And I should see that "Updated Phase" is not a milestone and shown in aggregation

  Scenario: The admin may delete a type
     When I go to the global index page of types
      And I follow "Delete Minor Phase"
     Then I should see a notice flash stating "Successful deletion."
      And I should not see the "Minor Phase" type

  Scenario: The admin may reorder types
     When I go to the global index page of types
      And I move "Minor Phase" to the top
     Then "Minor Phase" should be the first element in the list

     When I move "Minor Phase" down by one
     Then "Phase" should be the first element in the list

  Scenario: A standard type cannot be deleted
     When I go to the global index page of types
     Then "Standard" should be the last element in the list
      And I should not see "Delete" within "table.timelines-pet tbody tr:last td:last"
