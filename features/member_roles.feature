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

Feature: Unchanged Member Roles

  @javascript
  Scenario: Global Roles should not be displayed as assignable project roles
    Given there is 1 project with the following:
      | Name | projectname |
      | Identifier | projectid |
    And there is a global role "GlobalRole1"
    And there is a role "MemberRole1"
    And I am already admin
    When I go to the members tab of the settings page for the project "projectid"
    And I enter the role name "MemberRole1"
    Then I should see "MemberRole1"
    And I enter the role name "GlobalRole1"
    Then I should not see "GlobalRole1"
