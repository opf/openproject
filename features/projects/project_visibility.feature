Feature: Project Visibility

Background:
	Given there is 1 project with the following:
        | name            | Bob's Accounting     |
        | identifier      | bobs-accounting      |

    Then the project "Bob's Accounting" is public

@javascript
Scenario: A Project is visible on the landing page if it is set to public
	  Given I am admin
	  And I am on the admin page
	  And I open the "Openproject Admin" menu
      When I follow "Sign out" within "#top-menu-items"
      Then I should see "Bob's Accounting" within "#content" 

@javascript
Scenario: Project is not visible on the landing page if it is not set to public
	   Given I am admin
	   And the project "Bob's Accounting" is not public
	   And I open the "Openproject Admin" menu
	   When I follow "Sign out" within "#top-menu-items"
       Then I should not see "Bob's Accounting" within "#content" 
