#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Feature: Filtering work packages via the api
  Background:
    Given there is 1 project with the following:
      | identifier | sample_project |
      | name       | sample_project |
    And I am working in project "sample_project"
    And the project "sample_project" has the following types:
      | name    | position |
      | Bug     |     1    |
      | Story   |     2    |
      | Epic    |     3    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a issuepriority with:
      | name   | High |
    And there is a issuepriority with:
      | name   | Immediate |
    And there are the following issue status:
      | name        | is_closed  | is_default  |
      | New         | false      | true        |
    And the project uses the following modules:
      | timelines |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_projects                 |
      | view_work_packages            |
      | view_timelines                |
      | view_planning_elements        |
      | edit_planning_elements        |
      | view_reportings               |

    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "sample_project"

    And there are 20 work packages of type "Bug" in project "sample_project"
    And there are 3 work packages of type "Story" in project "sample_project"

    And I am already logged in as "bob"

  Scenario: Benchmarking without filters
    When I call the work_package-api on project "sample_project" requesting format "json" without any filters
    Then the json-response should include 23 work packages
    And the time to get the unfiltered results should not exceed 0.1s


  Scenario: Benchmarking the filtering for type
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Story"
    Then the json-response should include 3 work packages
    And the time to get the filtered results should not exceed 0.1s

  Scenario: Filtering should be faster than not filtering
    When I call the work_package-api on project "sample_project" requesting format "json" filtering for type "Story"
    When I call the work_package-api on project "sample_project" requesting format "json" without any filters
    Then the time to get the filtered results should be faster than the time to get the unfiltered results



