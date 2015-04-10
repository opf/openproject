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

Feature: Localized boolean custom fields can be created

  Background:
    Given I am already admin
    And the following languages are active:
      | en |
      | de |
    And there are the following types:
      | name    | position |
      | Bug     |    1     |
      | Feature |    2     |
      | Support |    3     |
    When I go to the custom fields page
    When I follow "New custom field" within "#tab-content-WorkPackageCustomField"

  @javascript
  Scenario: Available fields
    When I select "Boolean" from "custom_field_field_format"
    Then there should be the following localizations:
      | locale  | name    | default_value |
      | en      |         | 0             |
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
