Feature: As an admin
         I want to administrate roles with permissions
         So that I can modify permissions of roles

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Issues can be assigned to this role"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Successful creation."

  @javascript
  Scenario: Normal Role creation with existing role with same name
    And there is a role "Manager"
    And I am already admin
    When I go to the new page of "Role"
    Then I should see "Issues can be assigned to this role"
    When I fill in "Name" with "Manager"
    And I click on "Create"
    Then I should see "Name has already been taken"
