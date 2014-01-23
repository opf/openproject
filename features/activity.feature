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

Feature: Cost Object activities

  Background:
    Given there is a standard cost control project named "project1"
    And I am already admin

  Scenario: cost object is a selectable activity type
    When I go to the activity page of the project "project1"
    Then I should see "Budgets" within "#sidebar"

  Scenario: Generating a cost object creates an activity
    Given there is a variable cost object with the following:
      | project     | project1            |
      | subject     | Cost Object Subject |
      | created_on  | Time.now - 1.day    |
    When I go to the activity page of the project "project1"
     And I activate activity filter "Cost Objects"
    When I click "Apply"
    Then I should see "Cost Object Subject"

  Scenario: Updating a cost object creates an activity
    Given there is a variable cost object with the following:
      | project     | project1            |
      | subject     | cost_object1        |
      | created_on  | Time.now - 40.days  |
    And I update the variable cost object "cost_object1" with the following:
      | subject     | cost_object1_new_title  |
    When I go to the activity page of the project "project1"
     And I activate activity filter "Cost Objects"
    When I click "Apply"
    Then I should see "cost_object1_new_title"


