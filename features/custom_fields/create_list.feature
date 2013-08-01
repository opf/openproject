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

Feature: Localized list custom fields can be created

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    When I go to the custom fields page
    When I follow "New custom field" within "#tab-content-WorkPackageCustomField"

  @javascript
  Scenario: Creating a list custom field
    When I select "List" from "custom_field_field_format"
    And I set the english localization of the "name" attribute to "New Field"
    And I set the english localization of the "possible_values" attribute to "one\ntwo\nthree\n"
    And I set the english localization of the "default_value" attribute to "two"
    And I press "Save"
    And I follow "New Field"
    Then there should be the following localizations:
      | locale  | name        | possible_values  | default_value |
      | en      | New Field   | one\ntwo\nthree  | two           |
