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

Feature: A work packages changesets are displayed on the work package show page
  Background:
    Given there is 1 user with:
        | login | manager |
    And there is a role "manager"
    And there is a project named "ecookbook"
    And the project "ecookbook" has a repository
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | timelines |
    And the user "manager" is a "manager"
    And there are the following work packages in project "ecookbook":
      | subject | start_date | due_date   |
      | wp1     | 2013-01-01 | 2013-12-31 |
    And the work package "wp1" has the following changesets:
      | revision | committer | committed_on | comments | commit_date |
      | 1        | manager   | 2013-02-01   | blubs    | 2013-02-01  |
    And I am already logged in as "manager"

  @javascript
  Scenario: Going to the work package show page and seeing the changesets because the user is allowed to see them
    Given the role "manager" may have the following rights:
        | view_work_packages |
        | view_changesets    |
    When I go to the page of the work package "wp1"
    Then I should see the following changesets:
        | revision | comments |
        | 1        | blubs    |

  @javascript
  Scenario: Going to the work package show page and not seeing the changesets because the user is not allowed to see them
    Given the role "manager" may have the following rights:
        | view_work_packages |
    When I go to the page of the work package "wp1"
    # Safeguard to ensure the page is loaded
    Then I should see "wp1" within ".wp-edit-field.subject"
    Then I should not be presented changesets
