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

Feature: Editing text custom fields

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    And the following issue custom fields are defined:
      | name             | type      |
      | My Custom Field  | text      |

  @javascript
  Scenario: Adding localized default_values
    When I go to the custom fields page
    And I follow "My Custom Field"
    And I set the english localization of the "default_value" attribute to "default"
    And I add the german localization of the "default_value" attribute as "Standard"
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale  | default_value   | name              |
      | en      | default         | My Custom Field   |
      | de      | Standard        | nil               |

  @javascript
  Scenario: Changing a localization which is not present for any other attribute to a locale existing in another attribute deletes the localization completely
    When the Custom Field called "My Custom Field" has the following localizations:
      | locale        | name            | default_value   |
      | en            | My Custom Field | nil             |
      | de            | nil             | default         |
    And I go to the custom fields page
    And I follow "My Custom Field"
    And I select "English" from "custom_field_translations_attributes_1_locale"
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name            | default_value |
      | en     | My Custom Field | default       |

  @javascript
  Scenario: Changing a localization of one attribute to a non existent localization creates the localization
    When the Custom Field called "My Custom Field" has the following localizations:
      | locale        | name            | default_value   |
      | en            | My Custom Field | default         |
    And I go to the custom fields page
    And I follow "My Custom Field"
    And I select "Deutsch" from "custom_field_translations_attributes_0_locale"
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale  | name            | default_value  |
      | en      | nil             | default        |
      | de      | My Custom Field | nil            |


