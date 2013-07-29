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

Feature: Former Passwords are banned from reuse
    Scenario: A user trying to reuse two former passwords
        Given users are not allowed to reuse the last 2 passwords
        And I am logged in
        When I try to set my new password to "adminADMIN!"
        Then there should be an error message
        When I try to set my new password to "adminADMIN!New"
        Then the password change should succeed
        When I try to change my password from "adminADMIN!New" to "adminADMIN!Third"
        Then the password change should succeed
        When I try to change my password from "adminADMIN!Third" to "adminADMIN!Third"
        Then there should be an error message
        When I try to change my password from "adminADMIN!Third" to "adminADMIN!New"
        Then there should be an error message
        When I try to change my password from "adminADMIN!Third" to "adminADMIN!"
        Then the password change should succeed

    Scenario: Former passwords are allowed
        Given users are not allowed to reuse the last 0 passwords
        And I am logged in
        When I try to set my new password to "adminADMIN!"
        Then the password change should succeed
