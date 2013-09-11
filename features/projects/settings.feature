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

Feature: Project Settings
  Background:
    Given there is 1 project with the following:
      | name        | project1 |
      | identifier  | project1 |
    And there is 1 user with the following:
      | login     | bob        |
      | firstname | Bob        |
      | Lastname  | Bobbit     |
    And there is 1 user with the following:
      | login     | alice      |
      | firstname | Alice      |
      | Lastname  | Alison     |
    And there is a role "alpha"
    And there is a role "beta"
    And the user "bob" is a "alpha" in the project "project1"
    And the user "alice" is a "beta" in the project "project1"
    Given I am already admin

  @javascript
  Scenario: Adding a Role to a Member
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I check "beta" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then I should see "alpha" within "#member-1-roles"
    And I should see "beta" within "#member-1-roles"

  @javascript
  Scenario: Removing one Role from while adding another Role to a Member
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I uncheck "alpha" within "#member-1-roles-form"
    And I check "beta" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then I should see "beta" within "#member-1-roles"
    And I should not see "alpha" within "#member-1-roles"

  @javascript
  Scenario: Removing the last Role of a Member
    When I go to the members tab of the settings page of the project "project1"
    When I click on "Edit" within "#member-1"
    And I uncheck "alpha" within "#member-1-roles-form"
    And I click "Change" within "#member-1-roles-form"
    Then there should be an error message
    And I should see "Bob Bobbit" within ".list.members"
    And I should see "alpha" within ".list.members"

  @javascript
  Scenario: Changing members per page keeps us on the members tab
    When I go to the settings page of the project "project1"
    And I follow "Members" within ".tabs"
    And I follow "50" within ".per_page_options" within "#tab-content-members"
    Then I should be on the members tab of the settings page of the project "project1"

  @javascript
  Scenario: Adding a Work Package custom field to the project
    When the following issue custom fields are defined:
      | name             | type      | is_for_all |
      | My Custom Field  | text      | false      |
    And I go to the settings page of the project "project1"
    And I check "My Custom Field" within "#tab-content-info"
    And I press "Save" within "#tab-content-info"
    Then the "My Custom Field" checkbox should be checked
