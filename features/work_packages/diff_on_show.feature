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

Feature: Having an inline diff view for work package description changes
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am working in project "parent"
    And the project "parent" has the following types:
      | name | position |
      | Bug  |     1    |
    And there is a default issuepriority with:
      | name   | Normal |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_work_packages |
    And there is 1 user with the following:
      | login     | bob    |
      | firstname | Bob    |
      | lastname  | Bobbit |
      | admin     | true   |
    And the user "bob" is a "member" in the project "parent"
    Given the user "bob" has 1 issue with the following:
      | subject     | wp1                 |
      | description | Initial description |
    And I am already logged in as "bob"

  @javascript @wip
  Scenario: A work package with a changed description links to the activity details
    # This fails on travis but is green locally; I guess due to database issues
    Given the work_package "wp1" is updated with the following:
      | description | Altered description |
    And journals are not being aggregated
    When I go to the page of the work package "wp1"
    Then I follow the link to see the diff in the last journal
    # Actually 'Initial' is being displayed as strikethrough text which
    # is hard to cover with plain text comparison
    And I should see "Altered Initial description"
