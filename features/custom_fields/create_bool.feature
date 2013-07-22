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

Feature: Localized boolean custom fields can be created

  Background:
    Given I am admin
    And the following languages are active:
      | en |
      | de |
    And there are the following types:
      | name    | position |  is_in_chlog |
      | Bug     |    1     |  true        |
      | Feature |    2     |  true        |
      | Support |    3     |  false       |
    When I go to the custom fields page
    When I follow "New custom field" within "#tab-content-WorkPackageCustomField"

  @javascript
  Scenario: Available fields
    When I select "Boolean" from "custom_field_field_format"
    Then there should be the following localizations:
      | locale  | name    | default_value | possible_values |
      | en      |         | 0             |                 |
    And there should be a "custom_field_type_ids_1" field visible
    And I should see "Bug"
    And there should be a "custom_field_type_ids_2" field visible
    And I should see "Feature"
    And there should be a "custom_field_type_ids_3" field visible
    And I should see "Support"
    And there should be a "custom_field_is_required" field visible
    And there should be a "custom_field_is_for_all" field visible
    And there should be a "custom_field_is_filter" field visible
    And there should be a "custom_field_searchable" field invisible

  @javascript
  Scenario: Creating a boolean custom field
    And I add the english localization of the "name" attribute as "New Field"
    And I select "Boolean" from "custom_field_field_format"
    Then I should not see "Possible values"
