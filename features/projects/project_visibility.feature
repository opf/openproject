Feature: Project Visibility

Background:
	Given I am logged in as "admin"
     When I go to the admin page
      And I follow "Projects"
      And I follow "New project"
      And I fill in "Bob's Accounting" for "Name"
      And I fill in "bob-s-accounting" for "Identifier"
      And I check "Public"
      And I press "Save"

@javascript
Scenario: A Project is visible on the landing page if it is set to public
	  Given I am on the admin page
	  And I open the "Openproject Admin" menu
      When I continue with "Sign out" in ".menu_root"
      Then I should see "Bob's Accounting" within "#content" 

@javascript
Scenario: Project is not visible on the landing page if it is not set to public
	   Given I am on the admin page
	   And I go to the overview page of the project "Bob's Accounting"
	   And I follow "Project settings" within "#menu-sidebar"
	   And the "Public" checkbox should be checked
	   And I uncheck "Public"
	   And I click "Save"
	   And I open the "Openproject Admin" menu
	   When I continue with "Sign out" in ".menu_root"
       Then I should not see "Bob's Accounting" within "#content" 
