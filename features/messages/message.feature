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

Feature: Issue textile quickinfo links

  Background:
    Given there is 1 project with the following:
      | name       | parent |
      | identifier | parent |
    And I am working in project "parent"
    And there is a board "development discussion" for project "parent"
    And there is a role "member"
    And the role "member" may have the following rights:
      | manage_boards       |
      | add_messages        |
      | edit_messages       |
      | edit_own_messages   |
      | delete_messages     |
      | delete_messages     |
      | delete_own_messages |
    And there is 1 user with the following:
      | login | bob |
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

  Scenario: Message's reply count is zero
    Given the board "development discussion" has the following messages:
      | message #1 |
    When I go to the message page of message "message #1"
    Then I should not see "Replies"

  Scenario: Message's reply count is two
    Given the board "development discussion" has the following messages:
      | message #1 |
    And "message #1" has the following replies:
      | reply #1 |
      | reply #2 |
    When I go to the message page of message "message #1"
    Then I should see "Replies (2)"

  Scenario: Check field value after error message raise when title is empty
    When I go to the boards page of the project called "parent"
    And I follow "New message"
    And I fill in "New relase FAQ" for "message_subject"
    When I click on the first button matching "Create"
    Then there should be an error message
    Then the "message_subject" field should contain "New relase FAQ"

  Scenario: Check field value after error message raise when description is empty
    When I go to the boards page of the project called "parent"
    And I follow "New message"
    And I fill in "Here you find the most frequently asked questions" for "message_content"
    When I click on the first button matching "Create"
    Then there should be an error message
    Then the "message_content" field should contain "Here you find the most frequently asked questions"

  @javascript
  Scenario: Sticky message on top of messages list
    Given the board "development discussion" has the following messages:
      | message #1 |
      | message #2 |
      | message #3 |
    When I go to the boards page of the project called "parent"
    And I follow "New message"
    And I fill in "How to?" for "message_subject"
    And I fill in "How to st-up project on local mashine." for "message_content"
    And I check "Sticky"
    When I click on the first button matching "Create"
    And I go to the boards page of the project called "parent"
    Then "How to?" should be the first row in table
