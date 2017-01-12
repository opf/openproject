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

Feature: Viewing a planning_element

  Background:
    Given there are the following types:
          | Name  | Is Milestone | In aggregation | Is default |
          | Phase | false        | true           | true       |
      And there are the following project types:
          | Name                  |
          | Standard Project      |
      And there is 1 user with:
          | login | manager |
      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines           |
          | view_work_packages       |
      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"
      And the project uses the following modules:
          | timelines |
      And the user "manager" is a "manager"
      And there are the following work packages in project "ecookbook":
        | subject | start_date | due_date   |
        | pe1     | 2013-01-01 | 2013-12-31 |
      And I am already logged in as "manager"

  @javascript
  Scenario: Opening the planning element page and viewing the planning element
    When I go to the page of the planning element "pe1" of the project called "ecookbook"
    Then I should see "pe1"
