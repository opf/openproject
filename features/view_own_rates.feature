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

Feature: Permission View Own hourly and cost rates

  @javascript
  Scenario: Users that by set permission are only allowed to see their own rates, can not see the rates of others.
    Given there is a standard cost control project named "Standard Project"
    And the role "Supplier" may have the following rights:
      | view_own_hourly_rate  |
      | view_work_packages           |
      | view_work_packages    |
      | view_own_time_entries |
      | view_own_cost_entries |
      | view_cost_rates       |
      | log_costs             |
    And there is 1 User with:
      | Login         | testuser |
      | Firstname     | Bob     |
      | Lastname      | Bobbit  |
      | default rate | 10.00 |
    And the user "testuser" is a "Supplier" in the project "Standard Project"
    And the project "Standard Project" has 1 issue with the following:
      | subject  | test_work_package |
    And the issue "test_work_package" has 1 time entry with the following:
      | hours | 1.00  |
      | user  | testuser   |
    And there is 1 cost type with the following:
      | name | Translation |
      | cost rate | 7.00   |
    And the work package "test_work_package" has 1 cost entry with the following:
      | units | 2.00  |
      | user  | testuser   |
      | cost type | Translation |
    And the user "manager" has:
      | hourly rate | 11.00 |
    And the issue "test_work_package" has 1 time entry with the following:
      | hours | 3.00 |
      | user | manager |
    And the work package "test_work_package" has 1 cost entry with the following:
      | units | 5.00 |
      | user | manager |
      | cost type | Translation |
    And I am already logged in as "testuser"
   When I am on the page for the issue "test_work_package"
   Then I should see "1 hour"
    And I should see "2 Translations"
    And I should see "24.00 EUR"
    And I should not see "33.00 EUR" # labour costs only of Manager
    And I should not see "35.00 EUR" # material costs only of Manager
    And I should not see "43.00 EUR" # labour costs of me and Manager
    And I should not see "49.00 EUR" # material costs of me and Manager
   When I am on the work_packages page for the project called "Standard Project"
   # ensure the page is loaded before opening the columns dropdown. Otherwise
   # there will be no columns to choose from.
    And I should see "status" within ".work-package-table--container"
    And I choose "Columns" from the toolbar "settings" dropdown
    And I select to see columns
        | Overall costs |
        | Labor costs   |
        | Unit costs    |
    And I click "Apply"
   Then I should see "EUR 24.00"
    And I should see "EUR 10.00"
    And I should see "EUR 14.00"
    And I should not see "EUR 33.00" # labour costs only of Manager
    And I should not see "EUR 35.00" # material costs only of Manager
    And I should not see "EUR 43.00" # labour costs of me and Manager
