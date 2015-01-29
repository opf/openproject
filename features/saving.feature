#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Feature: Saving Queries

  @javascript
  Scenario: Reports can be saved as private
    Given there is a standard cost control project named "First Project"
    And the role "Controller" may have the following rights:
      | view_own_hourly_rate      |
      | view_hourly_rates         |
      | view_cost_rates           |
      | view_own_time_entries     |
      | view_own_cost_entries     |
      | view_cost_entries         |
      | view_time_entries         |
      | save_cost_reports         |
      | save_private_cost_reports |
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then I should see "Save" within "#query-icon-save-as"
    And I click on "Clear"
    And I group columns by "Work package"
    And I group rows by "Project"
    And I set the filter "user_id" to the user with the login "developer" with the operator "!"
    And I click on "Save"
    And I fill in "Testreport" for "query_name"
    And I click on "Save" within "#save_as_form"
    Then I should see "Testreport" within "#ur_caption"
    And I should see "Testreport" within "#private_sidebar_report_list"
    And I should see "Work package" in columns
    And I should see "Project" in rows
    And filter "user_id" should be visible

  @javascript
  Scenario: Reports can be saved as public
    Given there is a standard cost control project named "First Project"
    And the role "Controller" may have the following rights:
      | view_own_hourly_rate      |
      | view_hourly_rates         |
      | view_cost_rates           |
      | view_own_time_entries     |
      | view_own_cost_entries     |
      | view_cost_entries         |
      | view_time_entries         |
      | save_cost_reports         |
      | save_private_cost_reports |
    And I am already logged in as "controller"
    And I am on the Cost Reports page for the project called "First Project"
    Then I should see "Save" within "#query-icon-save-as"
    And I click on "Clear"
    And I group columns by "Work package"
    And I group rows by "Project"
    And I set the filter "user_id" to the user with the login "developer" with the operator "!"
    And I click on "Save"
    And I fill in "Testreport" for "query_name"
    And I check "Public"
    And I click on "Save" within "#save_as_form"
    Then I should see "Testreport" within "#ur_caption"
    And I should see "Testreport" within "#public_sidebar_report_list"
    And I should see "Work package" in columns
    And I should see "Project" in rows
    And filter "user_id" should be visible

  @javascript
  Scenario: Reports can't be saved by users without permissions
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_time_entries        |
    And I am already logged in as "testuser"
    And I am on the Cost Reports page for the project called "Permission_Test"
    Then I should not see "Save" within ".buttons"

  @javascript
  Scenario: Public Reports can't be saved by users allowed to save private queries
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates         |
      | view_time_entries         |
      | save_private_cost_reports |
    And I am already logged in as "testuser"
    And I am on the Cost Reports page for the project called "Permission_Test"
    Then I should see "Save"
    And I click on "Save"
    Then I should not see "Public"
    And I fill in "Testreport" for "query_name"
    And I click on "Save" within "#save_as_form"
    Then I should see "Testreport" within "#ur_caption"
    And I should see "Testreport" within "#private_sidebar_report_list"

  @javascript
  Scenario: Users that can save cost reports can save either public or private
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates |
      | view_time_entries |
      | save_cost_reports |
    And I am already logged in as "testuser"
    And I am on the Cost Reports page for the project called "Permission_Test"
    Then I should see "Save" within "#query-icon-save-as"
    And I click on "Save"
    Then I should see "Public"
    And I fill in "Testreport" for "query_name"
    And I click on "Save" within "#save_as_form"
    Then I should see "Testreport" within "#ur_caption"
    And I should see "Testreport" within "#private_sidebar_report_list"
    Then I should see "Save" within "#query-icon-save-as"
    And I click on "Save Report As..."
    Then I should see "Public"
    And I check "Public"
    And I fill in "Testreport2" for "query_name"
    And I follow "Save" within "#save_as_form"
    Then I should see "Testreport2" within "#ur_caption"
    And I should see "Testreport2" within "#public_sidebar_report_list"
    And I should see "Testreport" within "#private_sidebar_report_list"
