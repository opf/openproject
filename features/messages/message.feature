#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
