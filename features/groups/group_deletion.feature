Feature: Simple deletion of a group

Background:
Given We have the group "Bob's Team"

@javascript
Scenario: An admin can delete an existing group
Given I am admin
Given I am on the groups administration page
And I click on "Delete"
And I accept the alert dialog
Then I should not see "Bob's Team" within "#content" 
