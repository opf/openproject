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

Feature: Filter

  @javascript
  Scenario: We got some awesome default settings
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then filter "spent_on" should be visible
    And filter "user_id" should be visible

  @javascript
  Scenario: A click on clear removes all filters
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    Then filter "spent_on" should not be visible
    And filter "user_id" should not be visible

  @javascript
  Scenario: A set filter is getting restored after reload
    Given there is a standard cost control project named "First Project"
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    And I click on "Clear"
    And I set the filter "user_id" to the user with the login "developer" with the operator "!"
    Then filter "user_id" should be visible
    When I send the query
    And the user with the login "developer" should be selected for "User Value"
    And "!" should be selected for "User Operator Open this filter with 'ALT' and arrow keys."

