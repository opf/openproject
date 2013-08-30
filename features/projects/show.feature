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

Feature: Showing Projects
  Background:
    Given there is 1 project with the following:
      | identifier | omicronpersei8 |
      | name       | omicronpersei8 |
    And I am working in project "omicronpersei8"
    And project "omicronpersei8" uses the following modules:
      | calendar |
    And there is a role "CanViewCal"
    And the role "CanViewCal" may have the following rights:
      | view_calendar   |
      | view_work_packages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "CanViewCal" in the project "omicronpersei8"
    And I am already logged in as "bob"

  Scenario: Calendar link in the 'tickets box' should work when calendar is activated
    When I go to the overview page of the project "omicronpersei8"
    Then I should see "Calendar" within "#content .issues.box"
    When I click on "Calendar" within "#content .issues.box"
    Then I should see "Calendar" within "#content > h2"
    And I should see "Sunday" within "#content > table.cal"
