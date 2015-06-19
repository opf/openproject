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

Feature: Attachments on work packages
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
      | edit_work_packages |
    And there is 1 user with the following:
      | login | bob|
    And the user "bob" has the following preferences
      | warn_on_leaving_unsaved | 0 |
    And the user "bob" is a "member" in the project "parent"
    And there are the following issue status:
      | name        | is_closed | is_default |
      | New         | false     | true       |
    Given the user "bob" has 1 issue with the following:
      | subject     | work package 1 |
      | type        | Bug    |
    Given the issue "work package 1" has an attachment "logo.gif"
    And I am already logged in as "bob"

  Scenario: A work package's attachment is listed
    When I go to the page for the issue "work package 1"
    Then I should see "logo.gif" within ".icon-attachment"

  Scenario: Deleting a work package's attachment is possible
    When I go to the page for the issue "work package 1"
    When I click the first delete attachment link
    Then I should not see ".icon-attachment"

  # see ticket #1916 on OpenProject.org
  @javascript
  Scenario: Deleting attachment while editing a work package
    When I go to the page for the work package "work package 1"
     And I select "Update" from the action menu
     And I fill in "Notes" with "Note message"

    When I click the first delete attachment link
     And I accept the alert dialog

    Then I should not see ".icon-attachment"
     And the "Notes" field should contain "Note message"
