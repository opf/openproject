#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

Feature: Resetting filters on work packages
  Background:
    Given there is a project named "project1"
    And the project "project1" has the following types:
      | name  | position |
      | Bug   | 1        |
      | Other | 2        |
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | view_work_packages |
    And there is 1 user with:
      | Login        | manager   |
    And the user "manager" is a "manager" in the project "project1"
    Given the user "manager" has 1 issue with the following:
      | subject | Some issue |
      | type    | Bug        |
    And I am already admin
    And I am on the work package index page of the project called "project1"

  @javascript
  Scenario: Clearing filters via the "Clear" buttons
    When I select "Type" from "Add filter"
    And I select "is" from "operators-type_id"
    And I select "Other" from "values-type_id"
    Then I should not see "Some issue"
    When I click "Clear"
    Then I should see "Some issue"
