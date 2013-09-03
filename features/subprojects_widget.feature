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

Feature: Subproject Widget

  Background:
    Given there is 1 project with the following:
      | Name | Parent |
    And the project "Parent" has 1 subproject with the following:
      | Name    | Child  |
    And there is a role "Admin"
    And there is a role "Manager"
    And I am already Admin

  @javascript
  Scenario: Adding a "Subproject" widget
    Given I am on the project "Parent" overview personalization page
    When I select "Subprojects" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "Subprojects" widget should be in the hidden block

  Scenario: Includes links to all child projects
    Given the following widgets are selected for the overview page of the "Parent" project:
      | top        | Subprojects   |
    And I am on the homepage for the project "Parent"
    And I follow "Child" within ".mypage-box .subprojects"
    Then I should be on the overview page of the project called "Child"


