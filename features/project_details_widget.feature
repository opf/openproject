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

Feature: Project Details Widget

  Background:
    Given there is 1 project with the following:
      | Name | Parent |
    And the project "Parent" has 1 subproject with the following:
      | Name    | Child  |
    And there is a role "Admin"
    And there is a role "Manager"
    And I am already Admin

  @javascript
  Scenario: Adding a "Calendar" widget
    Given I am on the project "Parent" overview personalization page
    When I select "Calendar" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Calendar" widget should be in the hidden block

  Scenario: Includes links to all child projects
    Given the following widgets are selected for the overview page of the "Parent" project:
      | top        | Project_details   |
    When I go to the overview page of the project called "Parent"
    And I follow "Child" within ".mypage-box .project_details"
    Then I should be on the overview page of the project called "Child"
