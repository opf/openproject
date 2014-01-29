
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
    And I fill in "rows:\n  row1:\n    test" for "export_card_configuration_rows"
    And I submit the form by the "Create" button
    Then I am on the export card configurations index page

   @javascript
   Scenario: Edit Existing Configuration
    Given there are multiple export card configurations
    And I am admin
    And I am on the export card configurations index page
    When I follow first "Custom 2"
    And I fill in "5" for "export_card_configuration_per_page"
    And I select "portrait" from "export_card_configuration_orientation"
    And I fill in "rows:\n  row1:\n    changed" for "export_card_configuration_rows"
    And I submit the form by the "Save" button
    Then I am on the export card configurations index page