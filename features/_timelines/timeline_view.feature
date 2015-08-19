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

Feature: Timeline View Tests
	As a Project Member
	I want to view the timeline data
	change the timeline selection

  Background:
    Given there is 1 user with:
          | login | manager |
      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines |
          | edit_timelines |
      And there is a project named "ecookbook"
      And I am working in project "ecookbook"
      And the project uses the following modules:
          | timelines |
      And the user "manager" is a "manager"
      And I am already logged in as "manager"

  Scenario: The project manager gets 'No data to display' when there are no planning elements defined
     When I go to the page of the timeline of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "General Settings"

  Scenario: Creating a timeline
     When there is a timeline "Testline" for project "ecookbook"
     When I go to the page of the timeline "Testline" of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "Testline"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

  @javascript
  Scenario: name column width
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
     Then the first table column should not take more than 25% of the space

  @javascript
  Scenario: Select columns
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the columns shown in the timeline to:
        | start_date |
        | type       |
        | due_date   |
      Then I should see the column "Start date" before the column "End date" in the timelines table
        And I should see the column "Start date" before the column "Type" in the timelines table
        And I should see the column "Type" before the column "End date" in the timelines table

  @javascript
  Scenario: switch timeline
    When there is a timeline "Testline" for project "ecookbook"
      And there is a timeline "Testline2" for project "ecookbook"
      And I go to the page of the project called "ecookbook"
      And I follow "Timelines"
      And I select "Testline2" from "Timeline report"
     Then I should see "New timeline report"
      And I should see "Testline2"
      And I should be on the page of the timeline "Testline2" of the project called "ecookbook"
