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

Feature: As an admin
         I want to administrate roles with permissions
         So that I can modify permissions of roles

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Work packages can be assigned to this role"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Successful creation."

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And there is a role "Manager"
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Work packages can be assigned to this role"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Name has already been taken"
