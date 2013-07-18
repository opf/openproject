Feature: Error Messages

  Background:
    Given I am admin

    Given there is a role "Manager"

      And there is 1 project with the following:
        | Name       | Project1 |
        | Identifier | project1 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

  @javascript
  Scenario: Adding a Principal, non impaired
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the principal "Peter Pan"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 flash error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 flash error messages

  @javascript
  Scenario: Adding a Role, non impaired
     When I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the role "Manager"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 flash error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 flash error messages

  @javascript
  Scenario: Adding a Principal, impaired
     When I am impaired
      And I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the principal "Peter Pan"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 flash error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 flash error messages

  @javascript
  Scenario: Adding a Role, impaired
     When I am impaired
      And I go to the settings page of the project called "Project1"
      And I click on "tab-members"
      And I select the role "Manager"
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should see 1 flash error message
      And I click on "Add" within "#tab-content-members"
      And I wait for AJAX
      Then I should not see 2 flash error messages