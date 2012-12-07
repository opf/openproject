Feature: Localized list custom fields can be created

  Background:
    Given I am admin
    And the following languages are active:
      | en |
      | de |
    When I go to the custom fields page
    When I follow "New custom field"

  @javascript
  Scenario: Creating a list custom field
    When I select "List" from "custom_field_field_format"
    And I add the english localization of the "name" attribute as "New Field"
    And I add the english localization of the "possible_values" attribute as "one\ntwo\nthree\n"
    And I add the english localization of the "default_value" attribute as "two"
    And I press "Save"
    And I follow "New Field"
    Then there should be the following localizations:
      | locale  | name        | possible_values  | default_value |
      | en      | New Field   | one\ntwo\nthree  | two           |
