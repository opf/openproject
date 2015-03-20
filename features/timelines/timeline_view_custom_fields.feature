#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Timeline View Tests
	As a Project Member
	I want to view the timeline data
	change the timeline selection

  Background:
    Given there is 1 user with:
          | login | manager |
      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_work_packages |
          | view_timelines     |
          | edit_timelines     |
          | edit_work_packages |

      And there are the following types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |

      And there is a project named "ecookbook"

      And the project "ecookbook" has the following types:
        | name    | position |
        | Phase   | 1        |

      And I am working in project "ecookbook"
      And the project uses the following modules:
          | timelines |
      And the user "manager" is a "manager"
      And I am already logged in as "manager"
      And the following work package custom fields are defined:
        | name    | type  | is_for_all | is_filter | possible_values |
        | cfBool  | bool  | true       | true      |                 |
        | cfList  | list  | true       | true      | A,B,C           |
        | cfUser  | user  | true       | true      |                 |
        | cfLocal | bool  | false      | true      |                 |

    And the custom field "cfBool" is activated for type "Phase"
    And the custom field "cfList" is activated for type "Phase"
    And the custom field "cfUser" is activated for type "Phase"
    And the custom field "cfLocal" is activated for type "Phase"

    And the custom field "cfLocal" is enabled for the project "ecookbook"

  @javascript
  Scenario: Select custom field column
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the columns shown in the timeline to:
        | start_date |
        | cf_1       |
        | due_date   |
      Then I should see the column "Start date" before the column "End date" in the timelines table
        And I should see the column "Start date" before the column "cfBool" in the timelines table
        And I should see the column "cfBool" before the column "End date" in the timelines table

  @javascript
  Scenario: Select custom field column and deactivate custom field
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the columns shown in the timeline to:
        | start_date |
        | cf_4       |
        | due_date   |
      And the custom field "cfLocal" is disabled for the project "ecookbook"
      Then I should see the column "Start date" immediately before the column "End date" in the timelines table

  @javascript
  Scenario: Show Boolean Custom Field Value
    Given I am working in the timeline "Testline" of the project called "ecookbook"
      And there are the following work packages in project "ecookbook":
          | Subject                  | Type  |
          | booleanTrue              | Phase |
          | booleanFalse             | Phase |
          | booleanNone              | Phase |

      And the work package "booleanTrue" has the custom field "cfBool" set to "1"
      And the work package "booleanFalse" has the custom field "cfBool" set to "0"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the columns shown in the timeline to:
        | start_date |
        | cf_1       |
        | due_date   |
      And I wait for timeline to load table
    Then I should see "Yes" in the row of the work package "booleanTrue"
      And I should see "No" in the row of the work package "booleanFalse"
      And I should not see "Yes" in the row of the work package "booleanNone"
      And I should not see "No" in the row of the work package "booleanNone"


  @javascript
  Scenario: Show Boolean Custom Field Value
    Given I am working in the timeline "Testline" of the project called "ecookbook"
      And there are the following work packages in project "ecookbook":
          | Subject     | Type  |
          | user        | Phase |

      And the work package "user" has the custom user field "cfUser" set to "manager"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the columns shown in the timeline to:
        | start_date |
        | cf_3       |
        | due_date   |
      And I wait for timeline to load table
    Then I should see "Bob Bobbit" in the row of the work package "user"
