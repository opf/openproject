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

Feature: Prevent brute force attacks
  Background:
    Given users are blocked for 5 minutes after 2 failed login attempts
    And there is a user named "bob"

  Scenario: A user failing to login on the first time can login on second attempt
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should see "Bob Bobbit"

  Scenario: A user can't login after two failed attempts, but can after waiting 5 minutes
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should not see "Bob Bobbit"
    When the time is 6 minutes later
    And I try to log in with user "bob"
    Then I should see "Bob Bobbit"

  Scenario: Brute force prevention is disabled
    Given users are blocked for 5 minutes after 0 failed login attempts
    When I try to log in with user "bob" and a wrong password
    Then I should not see "Bob Bobbit"
    When I try to log in with user "bob"
    Then I should see "Bob Bobbit"
