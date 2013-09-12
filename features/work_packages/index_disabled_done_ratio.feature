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

Feature: Disabled done ratio on the work package index

  Background:
    Given there is 1 project with the following:
      | identifier | project1 |
      | name       | project1 |
    And the project "project1" has the following types:
      | name | position |
      | Bug  |     1    |
    And the project "project1" has 4 issues with the following:
      | subject    | Issuesubject |
    And I am already admin

  @javascript
  Scenario: Column should be available when done ratio is enabled
    When I go to the work packages index page of the project "project1"
    And I click "Options"
    Then I should see "% done" within "#available_columns"

  @javascript
  Scenario: Column should not be available when done ratio is disabled
    Given the "issue_done_ratio" setting is set to disabled
    When I go to the work packages index page of the project "project1"
    And I click "Options"
    Then I should not see "% done" within "#available_columns"

  @javascript
  Scenario: Column is selected and done ratio is disabled afterwards
    When I go to the work packages index page of the project "project1"
    And I select to see columns
      | % done |
    Then I should see "% done" within ".list"
    Given the "issue_done_ratio" setting is set to disabled
    When I go to the work packages index page of the project "project1"
    Then I should not see "% done" within ".list"
