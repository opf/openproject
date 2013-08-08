Feature: Create Issues

Background:

And there is 1 user with:
		| Login     | arya   |
        | Firstname | Arya   |
        | Lastname  | Stark  |
And there is 1 project with the following:
		| Name       | Peanut |
        | Identifier | peanut |
And the project "Peanut" uses the following modules:
        | issue_tracking | 
 
 @javascript
 Scenario: Only users with the proper rights are able to create issues
 
 Given I am logged in as "arya"
 And there is a role "messenger"
 And the role "messenger" may have the following rights:
 		| add_issues         |
 		| view_issues        |
 		| view_work_packages |
 		| add_work_packages  | 

 And the user "arya" is a "messenger" in the project "Peanut"
 And I go to the home page
 And I go to the overview page of the project "Peanut"
 When I follow "Issues" within "#menu-sidebar"
 Then I should see "New issue" within "#menu-sidebar"
