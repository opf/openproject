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

# This addresses some of the forms of the admin's user panel
#
Feature: User

  Background:
    Given I am already admin

    Given there is a role "Manager"
      And there is a role "Developer"

      And there is 1 project with the following:
        | Identifier | project1 |
        | name       | Project1 |
      And there is 1 project with the following:
        | Identifier | project2 |
        | name       | Project2 |
      And there is 1 project with the following:
        | Identifier | project3 |
        | name       | Project3 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

      And there is 1 User with:
        | Login     | hannibal |
        | Firstname | Hannibal |
        | Lastname  | Smith    |

    And there is a role "alpha"
    And there is a role "beta"
    And there is a role "gamma"

  @javascript
  Scenario: Granting Membership to a project with one role
    When I go to the memberships tab of the edit page for the user peter
    And I select "Project1" from "membership_project_id"
    And I check the role "alpha"
    And I click "Add" within "#new_project_membership"
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    And I should not see membership to the project "project2"

  @javascript
  Scenario: Granting Membership to a project with multiple
    When I go to the memberships tab of the edit page for the user peter
    And I select "Project1" from "membership_project_id"
    And I check the role "alpha"
    And I check the role "beta"
    And I check the role "gamma"
    And I click "Add" within "#new_project_membership"
    Then I should see membership to the project "project1" with the roles:
      | alpha |
      | beta  |
      | gamma |
    And I should not see membership to the project "project2"

  @javascript
  Scenario: Revoking Membership to a project
    When the user "peter" is a "alpha" in the project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    When I delete membership to project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should not see membership to the project "project1"

  @javascript
  Scenario: Editing membership to a project
    When the user "peter" is a "alpha" in the project "project1"
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
    When I edit membership to project "project1" to contain the roles:
      | alpha |
      | beta  |
      | gamma |
    And I go to the memberships tab of the edit page for the user peter
    Then I should see membership to the project "project1" with the roles:
      | alpha |
      | beta  |
      | gamma |
