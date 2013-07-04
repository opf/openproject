Feature: Creating or editing a group

@javascript
Scenario: Admin is able to create a group without members

Given I am logged in as "admin"
And I open the "Modules" menu
And I follow "Administration" within ".menu_root"
And I follow "Groups" within "#menu-sidebar"
And I follow "New group" within "#content"
And I fill in "Name" with "Team-A"
When I click on "Create"
Then I should see "Successful creation."

@javascript
Scenario: Admin can add members on a group

Given I am logged in as "admin"
And there is 1 user with the following:
	  | login     |  bob    |
And there is 1 group with the following:
      | name      | B-Team     |
And I am on the groups administration page
And I follow "B-Team" within "#content"
And I click on "tab-users"
And I fill in "user_search" with "bob"
And I check "Bob Bobbit"
When I click "Add"
Then I should see "Bob Bobbit" within "#content"
