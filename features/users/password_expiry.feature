#encoding: utf-8

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

Feature: Pasword expiry
  Background:
    Given there is a user named "bob"
    And I am already logged in as "admin"

  Scenario: An admin activating password expiry forces a user to change the password
    When I set passwords to expire after 30 days
    # login should succeed
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit"
    When the time is 31 days later
    # 31 days later, the login should fail
    And I try to log in with user "bob"
    Then I should not see "Bob Bobbit"
    And there should be a flash error message
    # After changing the password, the user should be logged in
    When I fill out the change password form
    Then there should be a flash notice message
    And I should see "Bob Bobbit"

  Scenario: An admin deactivating password expiry allows a user to login
    When I set passwords to expire after 0 days
    # login should succeed
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit"
    When the time is 31 days later
    # 31 days later, the login should fail
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit"
