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

Feature: Projects index feed
  Background:
    Given there is 1 project with the following:
      | identifier | omicronpersei8 |
      | name       | omicronpersei8 |
    And there is a role "CanViewProject"
    And the role "CanViewProject" may have the following rights:
      | view_project   |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "CanViewProject" in the project "omicronpersei8"
    And I am already logged in as "bob"

   Scenario: Atom feed enabled
     When I go to the projects page
     Then I should see "Also available in" within ".other-formats"
      And I should see "Atom" within ".other-formats span"

   Scenario: Atom feed disabled
    Given the "feeds_disabled" setting is set to true
     When I go to the projects page
     Then I should not see "Also available in"
