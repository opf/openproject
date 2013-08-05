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

Feature: Creating Projects

  @javascript
  Scenario: Creating a Subproject
    Given there is 1 project with the following:
      | name        | Parent      |
      | identifier  | parent      |
    And I am already admin
    When I go to the overview page of the project "Parent"
    And I follow "New subproject"
    And I fill in "project_name" with "child"
    And I press "Save"
    Then I should be on the settings page of the project called "child"
