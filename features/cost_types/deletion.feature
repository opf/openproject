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

Feature: Cost type deletion

  Background:
    Given there is 1 cost type with the following:
      | name | cost_type1 |
    And I am already admin

  @javascript
  Scenario: Deleting a cost type
    When I delete the cost type "cost_type1"

    Then the cost type "cost_type1" should not be listed on the index page

  @javascript
  Scenario: Deleted cost types are listed as deleted
    When I delete the cost type "cost_type1"

    Then the cost type "cost_type1" should be listed as deleted on the index page

  @javascript
  Scenario: Click on the "delete" link for a cost type
    When I go to the index page of cost types

    Then I expect to click "OK" on a confirmation box saying "Are you sure?"
    And I click the delete link for the cost type "cost_type1"
    And the confirmation box should have been displayed
