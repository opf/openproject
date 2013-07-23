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

Feature: General Timelines adminstration
  As a ChiliProject Admin
  I want to see 'No data to display' instead of an empty table
  So that I can see the reason why I cannot see anything

  Scenario: The admin gets 'No data to display' when there are no colors defined
    Given I am admin
     When I go to the admin page
      And I follow "Colors"
     Then I should see "No data to display"
      And I should see "New color"

  Scenario: The admin gets 'No data to display' when there are no project types defined
    Given I am admin
     When I go to the admin page
      And I follow "Project types"
     Then I should see "No data to display"
      And I should see "New project type"

  Scenario: The admin gets 'No data to display' when there are no planning element types defined
    Given I am admin
     When I go to the admin page
      And I follow "Planning element types"
     Then I should see "No data to display"
      And I should see "New planning element type"
