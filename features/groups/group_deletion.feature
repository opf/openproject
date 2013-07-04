Feature: Simple deletion of a group

Background:
Given I am logged in as "admin"
And I open the "Modules" menu
And I follow "Administration" within ".menu_root"
And I follow "Groups" within "#menu-sidebar"
And I follow "New group" within "#content"
And I fill in "Name" with "Bob's Team"
When I click on "Create"
Then I should see "Successful creation."

@javascript
Scenario: An admin can delete an existing group
Given I am on the groups administration page
And I click on "Delete"
And I accept the alert dialog
Then I should not see "Bob's Team" within "#content" 
