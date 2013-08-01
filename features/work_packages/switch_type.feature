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

Feature: Switching types of work packages
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And I am working in project "project1"
    And the project "project1" has the following types:
      | name    | position |
      | Bug     | 1        |
      | Feature | 2        |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
      | edit_work_packages |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
    And the user "bob" is a "member" in the project "project1"
    Given the user "bob" has 1 issue with the following:
      | subject     | wp1                 |
      | description | Initial description |
      | type        | Bug                 |
    And I am already logged in as "bob"

  @javascript
  Scenario: Switching type should keep the inserted value
    When I go to the edit page of the work package "wp1"
    And I fill in the following:
      | Responsible | Bob Bobbit |
    And I follow "More"
    And I select "Feature" from "Type"

    Then I should be on the edit page of the work package "wp1"
    And I should see the following fields:
      | Responsible | Bob Bobbit |

  @javascript
  Scenario: Switching type should update the presented custom fields
    Given the following work package custom fields are defined:
      | name      | type |
      | cfBug     | int  |
      | cfFeature | int  |
      | cfAll     | int  |
    And the custom field "cfBug" is activated for type "Bug"
    And the custom field "cfFeature" is activated for type "Feature"
    And the custom field "cfAll" is activated for type "Bug"
    And the custom field "cfAll" is activated for type "Feature"

    When I go to the edit page of the work package "wp1"
    And I follow "More"
    And I fill in the following:
      | cfAll | 5 |
    And I select "Feature" from "Type"

    Then I should be on the edit page of the work package "wp1"
    And I should see the following fields:
      | cfFeature |   |
      | cfAll     | 5 |



