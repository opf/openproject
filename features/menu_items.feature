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

Feature: Menu items
  Background:
    Given there is 1 project with the following:
      | name            | Awesome Project      |
      | identifier      | awesome-project      |
    And project "Awesome Project" uses the following modules:
      | calendar |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_calendar  |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And I am already logged in as "bob"

  Scenario: Calendar menu should be visible when calendar is activated
    When I go to the overview page of the project "Awesome Project"
    Then I should see "Calendar" within "#main-menu"
