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

Feature: Updating Hourly Rates

  Background:
    Given there is a standard cost control project named "project1"
    And there is 1 user with:
        | login | admin |
        | admin | true |
    And I am already logged in as "admin"

  Scenario: The project member has a hourly rate valid from today
    Given there is an hourly rate with the following:
      | project     | project1            |
      | user        | manager             |
      | valid_from  | Date.today          |
      | rate        | 20                  |
    When I go to the members page of the project "project1"
     And I set the hourly rate of user "manager" to "30"
     And I go to the hourly rates page of user "manager" of the project called "project1"
    Then I should see 1 hourly rate

  Scenario: The project member does not have a hourly rate valid from today
    Given there is an hourly rate with the following:
      | project     | project1            |
      | user        | manager             |
      | valid_from  | Date.today - 1      |
      | rate        | 20                  |
    When I go to the members page of the project "project1"
     And I set the hourly rate of user "manager" to "30"
     And I go to the hourly rates page of user "manager" of the project called "project1"
     Then I should see 2 hourly rates
