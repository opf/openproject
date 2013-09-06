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

Feature: Parent wiki page

  Background:
    Given there is 1 project with the following:
      | Name | Test |
    And the project "Test" has 1 wiki page with the following:
      | Title | Test_page |
    Given the project "Test" has 1 wiki page with the following:
      | Title | Parent_page |
    And I am already admin

  @javascript
  Scenario: Changing parent page for wiki page
    When I go to the wiki page "Test page" for the project called "Test"
    And I click on "More functions"
    And I follow "Change parent page"
    When I select "Parent page" from "Parent page"
    And I press "Save"
    Then I should be on the wiki page "Test_page" for the project called "Test"
    And the breadcrumbs should have the element "Parent page"
    # no check removing the parent
    When I go to the wiki page "Test page" for the project called "Test"
    And I click on "More functions"
    And I follow "Change parent page"
    And I select "" from "Parent page"
    And I press "Save"
    Then I should be on the wiki page "Test_page" for the project called "Test"
    And the breadcrumbs should not have the element "Parent page"
