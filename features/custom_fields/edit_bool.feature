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

Feature: Editing a bool custom field

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    And the following issue custom fields are defined:
      | name              | type      |
      | IssueCustomField  | bool      |
    When I go to the custom fields page

  @javascript
  Scenario: Adding a localized name
    When I follow "IssueCustomField"
    And I set the english localization of the "name" attribute to "Issue Field"
    And I add the german localization of the "name" attribute as "Ticket Feld"
    And I press "Save"
    Then I should be on the custom fields page
    When I follow "Issue Field"
    Then there should be the following localizations:
      | locale  | name        | default_value |
      | en      | Issue Field | 0             |
      | de      | Ticket Feld | nil           |
    And I should not see "Add" within "#custom_field_name_attributes"

  Scenario: Entering a long name displays an error
    When I follow "IssueCustomField"
    And I fill in "custom_field_translations_attributes_0_name" with "Long name which forces an error"
    And I press "Save"
    Then the "custom_field_translations_attributes_0_name" field should contain "Long name which forces an error"
    And I should see "Name is too long" within "#errorExplanation"

  Scenario: Entering an already taken name displays an error
    Given the following issue custom fields are defined:
      | name              | type    |
      | Taken name        | bool    |
    When I follow "IssueCustomField"
    And I set the english localization of the "name" attribute to "Taken name"
    And I press "Save"
    Then I should see "Name has already been taken" within "#errorExplanation"
    And the "custom_field_translations_attributes_0_name" field should contain "Taken name"

