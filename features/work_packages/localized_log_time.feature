Feature: Adding localized time log
  Background:
    Given the following languages are active:
      | en |
      | de |
    And there is 1 user with:
      | login     | manager |
      | firstname | the     |
      | lastname  | manager |
      | language  | de      |
    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |
      | view_work_packages |
      | log_time           |
    And I am working in project "ecookbook"
    And the project uses the following modules:
      | time_tracking |
    And the user "manager" is a "manager"
    And there are the following status:
      | name    | default |
      | status1 | true    |
    And there are the following work packages in project "ecookbook":
      | subject | status_id |
      | pe1     | 1         |
    And there is an activity "design"
    And I am already logged in as "manager"

  @javascript
  Scenario: Adding a localized time entry
    Given I am on the edit page of the work package called "pe1"
    When I follow "Mehr"
    And I fill in the following:
    | Thema             |        |
    | Aufgewendete Zeit | 2,5    |
    | Aktivität         | design |
    And I submit the form by the "OK" button
    Then I should be on the page of the work package "pe1"
    And I should see 1 error message
    And the "work_package_time_entry_hours" field should contain "2,5"