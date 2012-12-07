Feature: Text custom fields can be created

  Background:
    Given I am admin
    And the following languages are active:
      | en |
      | de |
      | fr |
    When I go to the custom fields page
    When I follow "New custom field"

  @javascript
  Scenario: Creating a text custom field with multiple name and default_value localizations
    When I select "Text" from "custom_field_field_format"
    And I add the english localization of the "name" attribute as "New Field"
    And I add the german localization of the "name" attribute as "Neues Feld"
    And I add the french localization of the "name" attribute as "Lorem ipsum"
    And I add the english localization of the "default_value" attribute as "default"
    And I add the german localization of the "default_value" attribute as "Standard"
    And I add the french localization of the "default_value" attribute as "Lorem"
    And I press "Save"
    And I follow "New Field"
    Then there should be the following localizations:
      | locale  | name          | default_value  |
      | en      | New Field     | default        |
      | de      | Neues Feld    | Standard       |
      | fr      | Lorem ipsum   | Lorem          |

  Scenario: Creating a custom field with one name
    And I add the english localization of the "name" attribute as "Issue Field"
    And I press "Save"
    Then I should be on the custom fields page
