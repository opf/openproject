# encoding: utf-8

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

Feature: User Status
  Background:
    Given I am already admin
    Given there is a user named "bobby"

  @javascript
  Scenario: Users can be filtered by status
    Given the user "bobby" had too many recently failed logins
    And I filter the users list by status "active (1)"
    Then I should not see "bobby"
    And I should see "admin"
    And I should not see "Anonymous"
    And I filter the users list by status "locked temporarily (1)"
    Then I should see "bobby"
    And I should not see "admin"
    And I should not see "Anonymous"
    When the user "bobby" is locked
    And I filter the users list by status "locked permanently (1)"
    Then I should see "bobby"
    And I should not see "admin"
    And I should not see "Anonymous"
    And I filter the users list by status "locked temporarily (1)"
    Then I should see "bobby"
    And I should not see "admin"
    And I should not see "Anonymous"
    And I filter the users list by status "all (2)"
    Then I should see "bobby"
    And I should see "admin"
    And I should not see "Anonymous"

  @javascript
  Scenario: User can be unlocked on the index page
    Given the user "bobby" is locked
    When I filter the users list by status "locked permanently (1)"
    And I click "Unlock"
    Then I should not see "bobby"
    And I try to log in with user "bobby"
    Then I should see "Bob Bobbit"

  Scenario: A locked and blocked user gets unlocked and unblocked
    Given the user "bobby" is locked
    And the user "bobby" had too many recently failed logins
    When I edit the user "bobby"
    And I click "Unlock and reset failed logins"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit"

  Scenario: An active user gets locked
    When I edit the user "bobby"
    And I click "Lock permanently"
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"

  Scenario: A registered user gets activated
    Given the user "bobby" is registered and not activated
    When I try to log in with user "bobby"
    Then I should not see "Bob Bobbit"
    When I am already admin
    And I edit the user "bobby"
    And I click "Activate"
    When I try to log in with user "bobby"
    Then I should see "Bob Bobbit"
