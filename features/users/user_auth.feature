Feature: User Authentification


@javascript 
Scenario: A user gets a error message if the false credentials are filled in
Given I am logged in as "joe"
#When I fill in "username" with "jon" 
#And I fill in "password" with "doe"
Then I should see "Invalid user or password"

@javascript
Scenario: A user is able to login successfully with provided credentials
Given I am on the login page
And I am admin
And I open the "Openproject Admin" menu
Then I should see "My account" within "#top-menu-items" 


@javascript
Scenario: Lost password notification mail will not be sent in case incorrect mail is given
Given I am on the login page
And I open the "Openproject Admin" menu
And I follow "Lost password" within "#login-form"
#And I continue with "Lost password" in ".nosidebar"
Then I should be on the lost password page
And I fill in "mail" with "bilbo@shire.com"
And I click on "Submit"
Then I should see "Unknown user"
