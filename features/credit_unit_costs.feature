#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

Feature: Credit unit costs

  Background:
    Given there is a standard cost control project named "project1"
    And the project "project1" has 1 issue with the following:
      | subject | work_package1 |
    And the role "Manager" may have the following rights:
      | view_work_packages        |
      | edit_work_packages        |
      | view_work_packages |
      | edit_work_packages |
      | log_costs          |
    And there is 1 cost type with the following:
      | name        | cost_type_1 |
      | unit        | single_unit |
      | unit_plural | multi_unit  |

  @javascript @wip
  Scenario: Crediting units costs to an work_package
    When I am already logged in as "manager"
    And I go to the page of the work package "work_package1"
    And I select "Log unit costs" from the action menu
    And I fill in "cost_entry_units" with "100"
    And I select "cost_type_1" from "Cost type"
    And I press "Save"
    Then I should be on the page of the work package "work_package1"
