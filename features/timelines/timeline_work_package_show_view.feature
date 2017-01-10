#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

Feature: Timeline Work Package Show View
	As a Project Member
	I want edit planning elements to open in a new tab

  Background:
    Given there is 1 user with:
         | login | manager |
    And there is a role "manager"
    And the role "manager" may have the following rights:
        | view_timelines     |
        | edit_timelines     |
        | view_work_packages |
    And there is a project named "ecookbook"
    And I am working in project "ecookbook"
    And there is a timeline "Testline" for project "ecookbook"
    And the project uses the following modules:
        | timelines |
    And the user "manager" is a "manager"
    And there are the following work packages:
        | Start date | Due date   | description         | responsible | Subject  |
        | 2012-01-01 | 2012-01-31 | #2 http://google.de | manager     | January  |
        | 2012-02-01 | 2012-02-24 | Avocado Rincon      | manager     | February |
    And I am already logged in as "manager"

  @javascript
  Scenario: planning element click should show the plannin element
    When I go to the page of the timeline "Testline" of the project called "ecookbook"
    And I wait for timeline to load table
    And I should see "January"
    When I click on the Planning Element with name "January"
    Then I should see "January" in the new window
