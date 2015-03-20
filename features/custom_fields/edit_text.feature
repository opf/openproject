#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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

  @wip
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
      | de      | Standard        | My Custom Field   |

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
      | en      | My Custom Field | default        |
      | de      | My Custom Field | nil            |


