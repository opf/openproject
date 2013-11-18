#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: No Module

  Scenario: Global Rights Modules do not exist as Project -> Settings -> Modules
    Given there is the global permission "glob_test" of the module "global"
    And there is 1 project with the following:
      | name       | test |
      | identifier | test |
    And I am already admin
    When I go to the members tab of the settings page for the project "test"
    Then I should not see "Global"
