Feature: Name localizations of bool custom fields can be deleted

  Background:
    Given I am already logged in as "admin"
    And the following languages are active:
      | en |
      | de |
      | fr |
    And the following issue custom fields are defined:
      | name             | type      |
      | My Custom Field  | bool      |
    And the Custom Field called "My Custom Field" has the following localizations:
      | locale        | name                          |
      | en            | My Custom Field               |
      | de            | Mein Benutzerdefiniertes Feld |
    When I go to the custom fields page

  @javascript
  Scenario: Deleting a localized name
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name            | default_value |
      | en     | My Custom Field | 0             |

  @javascript
  Scenario: Deleting a name localization and adding another of same locale in same action
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    And I add the german localization of the "name" attribute as "Neuer Name"
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name             | default_value |
      | en     | My Custom Field  | 0             |
      | de     | Neuer Name       | nil           |

  @javascript
  Scenario: Deleting a name localization frees the locale to be used by other translation field
    When I follow "My Custom Field"
    And I delete the english localization of the "name" attribute
    And I change the german localization of the "name" attribute to be english
    And I press "Save"
    And I follow "Mein Benutzerdefiniertes Feld"
    Then there should be the following localizations:
      | locale | name                          | default_value |
      | en     | Mein Benutzerdefiniertes Feld | 0             |

  @javascript
  Scenario: Deleting a newly added localization
    When I follow "My Custom Field"
    And I add the french localization of the "name" attribute as "To delete"
    And I delete the french localization of the "name" attribute
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name                          | default_value |
      | en     | My Custom Field               | 0             |
      | de     | Mein Benutzerdefiniertes Feld | nil           |

  @javascript
  Scenario: Deletion link is hidden when only one localization exists
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    Then the delete link for the english localization of the "name" attribute should not be visible
