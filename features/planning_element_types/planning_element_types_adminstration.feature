#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Planning Element Type Adminstration
  As a ChiliProject Admin
  I want to configure which planning element types are available
  So that I can support my teams with useful settings while still controlling
  the total number of available planning element types
  So that my teams can work effectively

  Background:
    Given there are the following planning element types:
          | Name            | Is Milestone | In aggregation |
          | Phase           | false        | true           |
          | Milestone       | true         | true           |
          | Minor Phase     | false        | false          |
          | Minor Milestone | true         | false          |

      And I am admin

  Scenario: The admin may see all planning element types within the admin UI
     When I go to the admin page
      And I follow "Planning element types"
     Then I should see that "Phase" is not a milestone and shown in aggregation
      And I should see that "Milestone" is a milestone and shown in aggregation
      And I should see that "Minor Phase" is not a milestone and not shown in aggregation
      And I should see that "Minor Milestone" is a milestone and not shown in aggregation

  Scenario: The admin may create a planning element type
     When I go to the admin page
      And I follow "Planning element types"
      And I follow "New planning element type"
      And I fill in "New Phase" for "Name"
      And I press "Save"
     Then I should see a notice flash stating "Successful creation."
      And I should see that "New Phase" is not a milestone and shown in aggregation
      And "New Phase" should be the last element in the list

  Scenario: Nice error messages help fixing them
     When I go to the admin page
      And I follow "Planning element types"
      And I follow "New planning element type"
      And I fill in "" for "Name"
      And I press "Save"
     Then I should see an error explanation stating "Name can't be blank"

  Scenario: The admin may edit a planning element type
     When I go to the edit page of the planning element type called "Phase"
      And I fill in "Updated Phase" for "Name"
      And I press "Save"
     Then I should see a notice flash stating "Successful update."
      And I should see that "Updated Phase" is not a milestone and shown in aggregation

  Scenario: The admin may delete a planning element type
     When I go to the admin page
      And I follow "Planning element types"
      And I follow "Delete Minor Phase"
      And I press "Delete"
     Then I should see a notice flash stating "Successful deletion."
      And I should not see the "Minor Phase" planning element type

  Scenario: The admin may reorder planning element types
     When I go to the admin page
      And I follow "Planning element types"
      And I move "Minor Phase" to the top
     Then "Minor Phase" should be the first element in the list

     When I move "Minor Phase" down by one
     Then "Phase" should be the first element in the list
