#-- copyright
#
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Having an inline diff view for work package description changes
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am working in project "parent"
    And the project "parent" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
      | admin     | true   |
    And the user "bob" is a "member" in the project "parent"
    Given the user "bob" has 1 issue with the following:
      | subject     | wp1                 |
      | description | Initial description |
    And I am already logged in as "bob"

  @javascript
  Scenario: A work package with a changed description has a callable diff showing the changes inline
    Given the work_package "wp1" is updated with the following:
      | description | Altered description |

    When I go to the page of the work package "wp1"

    Then I follow the link to see the diff in the 1 journal
    And I should see the following inline diff on the page of the work package "wp1":
      | new       | Altered     |
      | old       | Initial     |
      | unchanged | description |
