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

Feature: Name localizations of bool custom fields can be deleted

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    And the following issue custom fields are defined:
      | name             | type      |
      | My Custom Field  | bool      |
    And the Custom Field called "My Custom Field" has the following localizations:
      | locale        | name                          |
      | en            | My Custom Field               |
      | de            | Mein Benutzerdefiniertes Feld |
    When I go to the custom fields page

  @wip
  @javascript
  Scenario: Deleting a localized name
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name            | default_value |
      | en     | My Custom Field | 0             |

  @wip
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

  @wip
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

  @wip
  @javascript
  Scenario: Deleting a newly added localization
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    And I press "Save"
    And I follow "My Custom Field"
    And I add the german localization of the "name" attribute as "To delete"
    And I delete the german localization of the "name" attribute
    And I press "Save"
    And I follow "My Custom Field"
    Then there should be the following localizations:
      | locale | name                          | default_value |
      | en     | My Custom Field               | 0             |

  @wip
  @javascript
  Scenario: Deletion link is hidden when only one localization exists
    When I follow "My Custom Field"
    And I delete the german localization of the "name" attribute
    Then the delete link for the english localization of the "name" attribute should not be visible
