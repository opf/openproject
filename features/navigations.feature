#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Feature: Navigating to reports page

  Scenario: Navigating to the cost report of a project which is a subproject
    Given there is 1 project with the following:
      | name | ParentProject |
      | identifier | parent_project_1 |
    And the project "ParentProject" has 1 subproject with the following:
      | name | SubProject |
      | identifier | parent_project_1_sub_1 |
    And there is 1 user with the following:
      | login | bob |
    And there is a role "Testrole"
    And the role "Testrole" may have the following rights:
      | view_cost_entries |
      | view_own_cost_entries |
    And the user "bob" is a "Testrole" in the project "SubProject"
    When I login as "bob"
    And I go to the page of the project called "SubProject"
    And I follow "Cost reports" within "#main-menu"
    Then I should see "Cost report" within "#content"
