#-- copyright
# OpenProject PDF Export Plugin
#
# Copyright (C)2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++


Feature: export card configurations Admin
  As an Admin
  I want to administer the export card configurations
  So that CRUD operations can be performed on them

  @javascript
  Scenario: View Configurations
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    Then I should see "Default"
    And I should see "Custom"
    And I should see "Custom 2"

  @javascript
  Scenario: Create New Configuration
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    When I follow "New Export Card Config"
    And I fill in "Config 1" for "export_card_configuration_name"
    And I fill in "5" for "export_card_configuration_per_page"
    And I select "landscape" from "export_card_configuration_orientation"
    And I fill in valid YAML for export config rows
    And I submit the form by the "Create" button
    Then I should see "Successful creation." within ".flash.notice"

   @javascript
   Scenario: Edit Existing Configuration
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    When I follow first "Custom 2"
    And I fill in "5" for "export_card_configuration_per_page"
    And I select "portrait" from "export_card_configuration_orientation"
    And I fill in valid YAML for export config rows
    And I submit the form by the "Save" button
    Then I should see "Successful update." within ".flash.notice"

   @javascript
   Scenario: Activate Existing Configuration
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    When I follow first "Activate"
    Then I should see "Config succesfully activated" within ".flash.notice"

   @javascript
   Scenario: Deactivate Existing Configuration
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    When I follow first "De-activate"
    Then I should see "Config succesfully de-activated" within ".flash.notice"