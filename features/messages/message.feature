#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Feature: Issue textile quickinfo links
  Background:
    Given there is 1 project with the following:
      | name        | parent      |
      | identifier  | parent      |
    And I am working in project "parent"
    And there is a board "development discussion" for project "parent"
    And there is a role "member"
    And the role "member" may have the following rights:
      | manage_boards          |
      | add_messages           |
      | edit_messages          |
      | edit_own_messages      |
      | delete_messages        |
      | delete_messages        |
      | delete_own_messages    |
    And there is 1 user with the following:
      | login | bob|
    And the user "bob" is a "member" in the project "parent"
    And I am already logged in as "bob"

  Scenario: Adding a message to a forum
    When I go to the boards page of the project called "parent"
    And I follow "New message"
    And I fill in "New relase" for "message_subject"
    And I fill in "We have release a new version of our software." for "message_content"
    When I click on the first button matching "Create"
    Then I should see "New relase" within "#content"
    Then I should see "We have release a new version of our software." within "#content"
