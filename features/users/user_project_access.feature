Feature: Project accession for a user with a valid membership

@javascript
Scenario: User is able to see the project so long he has a valid membership.
Given there is a role "super_user"
And there is 1 project with the following:
      | name        | P1 	      |
      | identifier  | p1      	  |
And there is 1 user with the following:
      | login     | tom        |	
And I am logged in as "tom"
And the user "tom" is a "super_user" in the project "P1"
And I open the "Projects" menu
And  I follow "View all projects" within ".menu_root"
Then I should see "P1" within "#content"
