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

Feature: Fields editable on work package edit
  Background:
    Given there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
    And the user "manager" has the following preferences
      | warn_on_leaving_unsaved | false |
    And there is a role "manager"
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And I am working in project "ecookbook"
    And the user "manager" is a "manager"
    And I am already logged in as "manager"

  @javascript
  Scenario: Going to the page and viewing all the fields
    Given there are the following types:
      | Name      | Is Milestone | In aggregation |
      | Phase     | false        | true           |
    And there are the following project types:
      | Name                  |
      | Standard Project      |
    And the project named "ecookbook" is of the type "Standard Project"
    And there is an issuepriority with:
      | name | prio1 |
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |
      | manage_subtasks    |
    And the project "ecookbook" has 1 version with:
      | name | version1 |
    And the following types are enabled for projects of type "Standard Project"
      | Phase |
    And there are the following work packages in project "ecookbook":
      | subject  | description     | start_date | due_date   | done_ratio | type  | responsible | assigned_to | priority | parent   | estimated_hours | fixed_version |
      | parentpe |                 |            |            | 0          | Phase |             |             | prio1    |          |                 |               |
      | pe1      | pe1 description | 2013-01-01 | 2013-12-31 | 30         | Phase | manager     | manager     | prio1    | parentpe | 5               | version1      |

    When I go to the edit page of the work package called "pe1"
    And I click the edit work package button

    When I click on "Relations"

    Then I should see "parentpe" within ".relation.parent"

  @javascript
  Scenario: Going to the page and viewing custom field fields
    Given the role "manager" may have the following rights:
      | view_work_packages |
      | edit_work_packages |

    And there are the following types:
      | Name      |
      | Phase     |
    And the project "ecookbook" has the following types:
      | name    | position |
      | Phase   | 1        |
    And the following work package custom fields are defined:
      | name | type  |
      | cf1  | int   |
    And the custom field "cf1" is activated for type "Phase"

    And there are the following work packages in project "ecookbook":
      | subject | type  |
      | pe1     | Phase |

    And the work package "pe1" has the custom field "cf1" set to "4"

    When I go to the edit page of the work package called "pe1"
    And I click the edit work package button

    Then I should see the following fields:
      | cf1 | 4 |
