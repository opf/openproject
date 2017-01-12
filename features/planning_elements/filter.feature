#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

Feature: Filtering work packages via the api
  Background:
    Given there is 1 project with the following:
      | identifier | sample_project |
      | name       | sample_project |
    And I am working in project "sample_project"
    And the project "sample_project" has the following types:
      | name  | position |
      | Bug   | 1        |
      | Task  | 2        |
      | Story | 3        |
      | Epic  | 4        |
    And there is a default issuepriority with:
      | name | Normal |
    And there is a issuepriority with:
      | name | High |
    And there is a issuepriority with:
      | name | Immediate |
    And there are the following issue status:
      | name         | is_closed | is_default |
      | New          | false     | true       |
      | In Progress  | false     | true       |
      | Closed       | false     | true       |

    And the project uses the following modules:
      | timelines |
    And there is a role "member"
    And the role "member" may have the following rights:
      | edit_work_packages |
      | view_projects      |
      | view_reportings    |
      | view_timelines     |
      | view_work_packages |

    And there is 1 user with the following:
      | login      | bob    |
      | firstname  | Bob    |
      | lastname   | Bobbit |
    And there is 1 user with the following:
      | login     | peter  |
      | firstname | Peter  |
      | lastname  | Gunn   |
    And there is 1 user with the following:
      | login      | pamela   |
      | firstname  | Pamela   |
      | lastname   | Anderson |
    And the user "bob" is a "member" in the project "sample_project"
    And the user "peter" is a "member" in the project "sample_project"
    And the user "pamela" is a "member" in the project "sample_project"
   And I am already logged in as "bob"

  Scenario: Call the endpoint of the api without filters
    Given  there are the following work packages in project "sample_project":
      | subject        | type  |
      | work_package#1 | Bug   |
      | work_package#2 | Story |
    When I call the work_package-api on project "sample_project" requesting format "json" without any filters
    Then the json-response should include 2 work packages
    And the json-response should contain a work_package "work_package#1"
    And the json-response should contain a work_package "work_package#2"

  Scenario: Call the api filtering for type
    Given there are the following work packages in project "sample_project":
      | subject          | type  | parent         |
      | work_package#1   | Bug   |                |
      | work_package#1.1 | Bug   | work_package#1 |
      | work_package#2   | Story |                |
      | work_package#2.1 | Story | work_package#2 |
      | work_package#3   | Epic  |                |
      | work_package#3.1 | Story | work_package#3 |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Bug"
    Then the json-response should include 2 work packages
    Then the json-response should not contain a work_package "work_package#2"
    And the json-response should contain a work_package "work_package#1"

  Scenario: Call the api filtering for status
    Given there are the following work packages in project "sample_project":
      | subject          | type  | status         |
      | work_package#1   | Bug   | New            |
      | work_package#2   | Story | In Progress    |
      | work_package#3   | Epic  | Closed         |

    When I call the work_package-api on project "sample_project" requesting format "json" filtering for status "In Progress"
    Then the json-response should include 1 work package
    Then the json-response should contain a work_package "work_package#2"
    And the json-response should not contain a work_package "work_package#1"

  Scenario: Filtering multiple types
    Given there are the following work packages in project "sample_project":
      | subject          | type  | parent         |
      | work_package#1   | Bug   |                |
      | work_package#1.1 | Bug   | work_package#1 |
      | work_package#3   | Epic  |                |
      | work_package#3.1 | Story | work_package#3 |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Bug,Epic"
    Then the json-response should include 3 work packages
    And the json-response should contain a work_package "work_package#1"
    And the json-response should contain a work_package "work_package#3"
    And the json-response should not contain a work_package "work_package#3.1"

 Scenario:  Filter out children of work packages, if they don't have the right type
   Given there are the following work packages in project "sample_project":
     | subject          | type  | parent         |
     | work_package#3   | Epic  |                |
     | work_package#3.1 | Story | work_package#3 |
   When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Epic"
   Then the json-response should include 1 work package
   And the json-response should contain a work_package "work_package#3"
   And the json-response should not contain a work_package "work_package#3.1"

  Scenario:  Filter out parents of work packages, if they don't have the right type
    Given there are the following work packages in project "sample_project":
      | subject        | type  |
      | work_package#1 | Bug   |
      | work_package#2 | Story |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Story"
    Then the json-response should include 1 work package
    And the json-response should not contain a work_package "work_package#1"
    And the json-response should contain a work_package "work_package#2"


  Scenario: correctly export parent-child-relations
    Given there are the following work packages in project "sample_project":
      | subject          | type  | parent           |
      | work_package#1   | Epic  |                  |
      | work_package#1.1 | Story | work_package#1   |
      | work_package#2   | Task  | work_package#1.1 |
    When I call the work_package-api on project "sample_project" requesting format "json" without any filters
    Then the json-response should include 3 work packages
    And the json-response should say that "work_package#1" is parent of "work_package#1.1"

  Scenario: Move parent-relations up the ancestor-chain, when intermediate packages are fitered
    Given there are the following work packages in project "sample_project":
      | subject            | type  | parent           |
      | work_package#1     | Epic  |                  |
      | work_package#1.1   | Story | work_package#1   |
      | work_package#1.1.1 | Task  | work_package#1.1 |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Epic,Task"
    Then the json-response should include 2 work packages
    And the json-response should not contain a work_package "work_package#1.1"
    And the json-response should contain a work_package "work_package#1"
    And the json-response should contain a work_package "work_package#1.1.1"
    And the json-response should say that "work_package#1" is parent of "work_package#1.1.1"

  Scenario: The parent should be rewired to the first ancestor present in the filtered set
    Given there are the following work packages in project "sample_project":
      | subject              | type | parent             |
      | work_package#1       | Epic |                    |
      | work_package#1.1     | Task | work_package#1     |
      | work_package#1.1.1   | Bug  | work_package#1.1   |
      | work_package#1.1.1.1 | Task | work_package#1.1.1 |

    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Epic,Task"
    Then the json-response should include 3 work packages
    And the json-response should say that "work_package#1.1" is parent of "work_package#1.1.1.1"

  Scenario: When all ancestors are filtered, the work_package should have no parent
    Given there are the following work packages in project "sample_project":
      | subject            | type  | parent           |
      | work_package#1     | Epic  |                  |
      | work_package#1.1   | Story | work_package#1   |
      | work_package#1.1.1 | Task  | work_package#1.1 |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Task"
    Then the json-response should include 1 work packages
    And the json-response should say that "work_package#1.1.1" has no parent

  Scenario: Children are filtered out
    Given there are the following work packages in project "sample_project":
      | subject          | type  | parent         |
      | work_package#1   | Epic  |                |
      | work_package#1.1 | Task  | work_package#1 |
      | work_package#1.2 | Story | work_package#1 |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Epic,Story"
    And the json-response should say that "work_package#1" has 1 child

  Scenario: Filtering for responsibles
    Given there are the following work packages in project "sample_project":
      | subject          | type  | responsible |
      | work_package#1   | Task  | bob         |
      | work_package#2   | Task  | peter       |
      | work_package#3   | Task  | pamela      |
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for responsible "peter"
    Then the json-response should include 1 work package
    And the json-response should not contain a work_package "work_package#1"
    And the json-response should contain a work_package "work_package#2"

  Scenario: looking up historical data
    Given the date is "2014/01/01"
    And there are the following work packages in project "sample_project":
      | subject          | type  | responsible |
      | work_package#1   | Task  | bob         |
      | work_package#2   | Task  | peter       |
      | work_package#3   | Task  | pamela      |
    Given the date is "2014/02/01"
    And the work_package "work_package#3" is updated with the following:
      | type        | Story       |
      | responsible | bob         |
    # resetting to today as plugins might depend on the current time
    Given the date is today
    And I call the work_package-api on project "sample_project" at time "2014/01/03" and filter for types "Story"
    Then the json-response should include 1 work package
    And the json-response for work_package "work_package#3" should have the type "Task"
    And the json-response for work_package "work_package#3" should have the responsible "pamela"

  Scenario: comparing due dates
    Given the date is "2014/01/01"
    And there are the following work packages in project "sample_project":
      | subject          | type  | responsible | due_date   |
      | work_package#1   | Task  | bob         | 2014/01/15 |
    Given the date is "2014/02/01"
    And the work_package "work_package#1" is updated with the following:
      | type        | Story       |
      | responsible | pamela      |
      | due_date    | 2014/01/20  |
    # resetting to today as plugins might depend on the current time
    Given the date is today
    And I call the work_package-api on project "sample_project" at time "2014/01/03" and filter for types "Story"
    Then the json-response for work_package "work_package#1" should have the due_date "2014/01/15"
    And the work package "work_package#1" has the due_date "2014/01/20"
