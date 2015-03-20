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

Feature: Text custom fields can be created

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    When I go to the custom fields page
    When I follow "New custom field" within "#tab-content-WorkPackageCustomField"

  @wip
  @javascript
  Scenario: Creating a text custom field with multiple name and default_value localizations
    When I select "Text" from "custom_field_field_format"
    And I set the english localization of the "name" attribute to "New Field"
    And I add the german localization of the "name" attribute as "Neues Feld"
    And I set the english localization of the "default_value" attribute to "default"
    And I add the german localization of the "default_value" attribute as "Standard"
    And I press "Save"
    And I follow "New Field"
    Then there should be the following localizations:
      | locale  | name          | default_value  |
      | en      | New Field     | default        |
      | de      | Neues Feld    | Standard       |

  Scenario: Creating a custom field with one name
    And I set the english localization of the "name" attribute to "Issue Field"
    And I press "Save"
    Then I should be on the custom fields page
