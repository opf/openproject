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
