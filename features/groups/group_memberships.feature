Feature: Group Memberships

  Background:
    Given there is a role "Manager"
      And there is a role "Developer"

      And there is 1 project with the following:
        | Name       | Project1 |
        | Identifier | project1 |

      And there is 1 User with:
        | Login     | peter |
        | Firstname | Peter |
        | Lastname  | Pan   |

      And there is 1 User with:
        | Login     | bob    |
        | Firstname | Bob    |
        | Lastname  | Bobbit |

      And there is 1 User with:
        | Login     | hannibal |
        | Firstname | Hannibal |
        | Lastname  | Smith    |

      And there is a group named "A-Team" with the following members:
        | peter |
        | bob   |


  @javascript
  Scenario: Adding a group to a project on the project's page adds the group members as well
    Given I am admin

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"
      And I check "A-Team"
      And I check "Manager"
      And I press "Add"
     Then I should be on the settings page of the project called "project1"
      And I should see "A-Team" within ".members"
      And I should see "Bob Bobbit" within ".members"
      And I should see "Peter Pan" within ".members"


  @javascript
  Scenario: Group-based memberships and individual memberships are handled separately
    Given I am admin

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"
      And I check "Bob Bobbit"
      And I check "Manager"
      And I press "Add"
      And I wait for the AJAX requests to finish

      And I check "A-Team"
      And I check "Developer"
      And I press "Add"
      And I wait for the AJAX requests to finish

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish

     Then I should see "Bob Bobbit" within ".members"
      And I should not see "A-Team" within ".members"
      And I should not see "Peter Pan" within ".members"


  @javascript
  Scenario: Removing a group from a project on the project's page removes all group members as well

    Given I am admin

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"
      And I check "A-Team"
      And I check "Manager"
      And I press "Add"

     Then I should be on the settings page of the project called "project1"
      And I wait for the AJAX requests to finish

     When I delete the "A-Team" membership
      And I wait for the AJAX requests to finish

     Then I should not see "A-Team" within ".members"
      And I should not see "Bob Bobbit" within ".members"
      And I should not see "Peter Pan" within ".members"

  @javascript
  Scenario: Adding a user to a group adds the user to projects as well
    Given I am admin

     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add"
      And I wait for the AJAX requests to finish

      And I click on "tab-users"
      And I check "Hannibal Smith"
      And I press "Add"
      And I wait for the AJAX requests to finish

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should see "Bob Bobbit" within ".members"
      And I should see "Peter Pan" within ".members"
      And I should see "Hannibal Smith" within ".members"


  @javascript
  Scenario: Removing a user from a group removes the user from projects as well
    Given I am admin

     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add"
      And I wait for the AJAX requests to finish

     When I click on "tab-users"
      And I delete "bob" from the group
      And I wait for the AJAX requests to finish

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should not see "Bob Bobbit" within ".members"
      And I should see "Peter Pan" within ".members"

  @javascript
  Scenario: Adding a group to project on the group's page adds the group members as well
    Given I am admin

     When I go to the admin page of the group called "A-Team"
      And I click on "tab-memberships"
      And I select "Project1" from "Projects"
      And I check "Manager"
      And I press "Add"
      And I wait for the AJAX requests to finish

     Then the project member "A-Team" should have the role "Manager"

     When I go to the settings page of the project called "project1"
      And I click on "tab-members"

     Then I should see "A-Team" within ".members"
      And I should see "Bob Bobbit" within ".members"
      And I should see "Peter Pan" within ".members"
