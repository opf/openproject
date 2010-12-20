Feature: No Module

  @javascript
  Scenario: Global Rights Modules do not exist as Project -> Settings -> Modules
    Given there is the global permission "glob_test" of the module "global"
    And there is 1 project with the following:
      | Name | Test |
    And I am admin
    When I go to the Settings page for the project called "Test"
    And I click on "tab-modules"
    Then I should not see "Global"
