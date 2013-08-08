Feature: Double membership with different role as an individual and as a group member in a project

Background:
Given I am admin
And there is a role "Stakeholder"
And there is a role "Manager"
And there is 1 project with the following:
		| Name       | WS |
        | Identifier | ws |
And there is 1 user with:
 		| Login     | j.cunnington |
        | Firstname | Jon 		   |
        | Lastname  | Cunnington   |

 And the user "j.cunnington" is a "Stakeholder" in the project "ws"
 And there is a group named "Money Makers" with the following members:
 		|j.cunnington|


 @javascript
 Scenario: Adding a project member as an individual and as a group member leads to double membership
 When I go to the settings page of the project called "WS"
 And I click on "tab-members"
 And I add the principal "Money Makers" as a member with the roles:
 		|Manager|
 Then I should see "Jon Cunnington" within ".members"
 And I should see "Money Makers" within ".members"
