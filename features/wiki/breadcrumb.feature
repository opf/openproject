Feature: Wiki menu items
  Background:
    Given there is 1 project with the following:
      | name        | Awesome Project      |
      | identifier  | awesome-project      |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_wiki_pages  |
      | edit_wiki_pages |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And the project "Awesome Project" has 1 wiki page with the following:
      | Title | Wiki |
    And the project "Awesome Project" has 1 wiki page with the following:
      | Title | Level1 |
    And the project "Awesome Project" has a child wiki page of "Level1" with the following:
      | Title | Level2 |
    And the project "Awesome Project" has a child wiki page of "Level2" with the following:
      | Title | Level3 |
    And I am already logged in as "bob"

  Scenario: Breadcrumb with wiki hierarchy and a different menu item name
    Given the project "Awesome Project" has a wiki menu item with the following:
      | title | Level3 |
      | name | SomethingCompletelyDifferent |
    When I go to the wiki page "Level3" for the project called "Awesome Project"
    Then I should see "Level1" within ".breadcrumb"
    And I should see "Level2" within ".breadcrumb"
    And I should not see "Level3" within ".breadcrumb"
    And I should see "SomethingCompletelyDifferent" within ".breadcrumb"

