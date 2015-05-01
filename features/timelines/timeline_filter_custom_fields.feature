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
        | cfBoolL | bool  | false      | true      |                 |
        | cfListL | list  | false      | true      | A,B,C           |

    And the custom field "cfBool" is activated for type "Phase"
    And the custom field "cfList" is activated for type "Phase"
    And the custom field "cfBoolL" is activated for type "Phase"
    And the custom field "cfListL" is activated for type "Phase"

  @javascript
  Scenario: filter for global boolean custom field values
    Given there are the following work packages in project "ecookbook":
          | Subject                  | Type  |
          | boolNone                 | Phase |
          | boolTrue                 | Phase |
          | boolFalse                | Phase |

      And the work package "boolFalse" has the custom field "cfBool" set to "0"
      And the work package "boolTrue" has the custom field "cfBool" set to "1"
      And I am working in the timeline "Testline" of the project called "ecookbook"
      And there is a timeline "Testline" for project "ecookbook"
    When I filter for work packages with custom boolean field "cfBool" set to "0"   
      And I wait for timeline to load table
    Then I should see the work package "boolFalse" in the timeline
      And I should not see the work package "boolTrue" in the timeline
      And I should not see the work package "boolNone" in the timeline
    When I filter for work packages with custom boolean field "cfBool" set to "1"
      And I wait for timeline to load table
    Then I should not see the work package "boolFalse" in the timeline
      And I should see the work package "boolTrue" in the timeline
      And I should not see the work package "boolNone" in the timeline
    When I filter for work packages with custom boolean field "cfBool" set to "-1"
      And I wait for timeline to load table
    Then I should not see the work package "boolFalse" in the timeline
      And I should not see the work package "boolTrue" in the timeline
      And I should see the work package "boolNone" in the timeline

  @javascript
  Scenario: filter for global list custom field values
    Given there are the following work packages in project "ecookbook":
          | Subject                  | Type  |
          | listNone                 | Phase |
          | listA                    | Phase |
          | listB                    | Phase |
          | listC                    | Phase |

      And the work package "listA" has the custom field "cfList" set to "A"
      And the work package "listB" has the custom field "cfList" set to "B"
      And the work package "listC" has the custom field "cfList" set to "C"
      And I am working in the timeline "Testline" of the project called "ecookbook"
      And there is a timeline "Testline" for project "ecookbook"
    When I filter for work packages with custom list field "cfList" set to "-1,B"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should not see the work package "listA" in the timeline
      And I should see the work package "listB" in the timeline
      And I should not see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfList" set to "A,C"
      And I wait for timeline to load table
    Then I should not see the work package "listNone" in the timeline
      And I should see the work package "listA" in the timeline
      And I should not see the work package "listB" in the timeline
      And I should see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfList" set to "-1,A,B,C"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should see the work package "listA" in the timeline
      And I should see the work package "listB" in the timeline
      And I should see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfList" set to "-1"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should not see the work package "listA" in the timeline
      And I should not see the work package "listB" in the timeline
      And I should not see the work package "listC" in the timeline

  @javascript
  Scenario: filter for local boolean custom field values
    Given the custom field "cfBoolL" is enabled for the project "ecookbook"
      And there are the following work packages in project "ecookbook":
          | Subject                  | Type  |
          | boolNone                 | Phase |
          | boolTrue                 | Phase |
          | boolFalse                | Phase |

      And the work package "boolFalse" has the custom field "cfBoolL" set to "0"
      And the work package "boolTrue" has the custom field "cfBoolL" set to "1"
      And I am working in the timeline "Testline" of the project called "ecookbook"
      And there is a timeline "Testline" for project "ecookbook"
    When I filter for work packages with custom boolean field "cfBoolL" set to "0"   
      And I wait for timeline to load table
    Then I should see the work package "boolFalse" in the timeline
      And I should not see the work package "boolTrue" in the timeline
      And I should not see the work package "boolNone" in the timeline
    When I filter for work packages with custom boolean field "cfBoolL" set to "1"
      And I wait for timeline to load table
    Then I should not see the work package "boolFalse" in the timeline
      And I should see the work package "boolTrue" in the timeline
      And I should not see the work package "boolNone" in the timeline
    When I filter for work packages with custom boolean field "cfBoolL" set to "-1"
      And I wait for timeline to load table
    Then I should not see the work package "boolFalse" in the timeline
      And I should not see the work package "boolTrue" in the timeline
      And I should see the work package "boolNone" in the timeline

  @javascript
  Scenario: filter for global list custom field values
    Given the custom field "cfListL" is enabled for the project "ecookbook"
      And there are the following work packages in project "ecookbook":
          | Subject                  | Type  |
          | listNone                 | Phase |
          | listA                    | Phase |
          | listB                    | Phase |
          | listC                    | Phase |

      And the work package "listA" has the custom field "cfListL" set to "A"
      And the work package "listB" has the custom field "cfListL" set to "B"
      And the work package "listC" has the custom field "cfListL" set to "C"
      And I am working in the timeline "Testline" of the project called "ecookbook"
      And there is a timeline "Testline" for project "ecookbook"
    When I filter for work packages with custom list field "cfListL" set to "-1,B"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should not see the work package "listA" in the timeline
      And I should see the work package "listB" in the timeline
      And I should not see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfListL" set to "A,C"
      And I wait for timeline to load table
    Then I should not see the work package "listNone" in the timeline
      And I should see the work package "listA" in the timeline
      And I should not see the work package "listB" in the timeline
      And I should see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfListL" set to "-1,A,B,C"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should see the work package "listA" in the timeline
      And I should see the work package "listB" in the timeline
      And I should see the work package "listC" in the timeline
    When I filter for work packages with custom list field "cfListL" set to "-1"
      And I wait for timeline to load table
    Then I should see the work package "listNone" in the timeline
      And I should not see the work package "listA" in the timeline
      And I should not see the work package "listB" in the timeline
      And I should not see the work package "listC" in the timeline
