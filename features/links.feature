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

Feature: Cost Reporting Linkage

  @javascript
  Scenario: Coming to the cost report for the first time, I should see no entries that are not my own
    Given there is a standard cost control project named "Some Project"
    And there is 1 cost type with the following:
      | name | Translation |
    And the user "manager" has 1 cost entry
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "Some Project"

    When I choose "Cash value"
    And I send the query

    Then I should see "User"
    # And I should see "me"
    And I should see "There is currently nothing to display."
    And I should not see "0.00"

  @javascript
  Scenario: Coming to the cost report for the first time, I should see my entries
    Given there is a standard cost control project named "Standard Project"
    And the user "manager" has:
      | hourly rate  | 10 |
      | default rate | 10 |
    And the user "manager" has 1 issue with:
      | subject | manager work_package |
    And the issue "manager work_package" has 1 time entry with the following:
      | user  | manager |
      | hours | 10      |
    And there is 1 cost type with the following:
      | name      | word |
      | cost rate | 1.01 |
    And the work package "manager work_package" has 1 cost entry with the following:
      | units     | 7       |
      | user      | manager |
      | cost type | word    |
    And I am already logged in as "manager"
    And I am on the Cost Reports page for the project called "Standard Project"

    When I choose "Cash value"
    And I send the query

    # 100 EUR (labour cost) + 7.07 EUR (words)
    Then I should see "107.07"
    And I should not see "No data to display"
