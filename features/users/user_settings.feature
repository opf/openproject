Feature: Update User Information

@javascript 
Scenario: A user is able to change his mail address if the settings permit it
Given I am admin
And   I open the "Openproject Admin" menu
Then  I should see "My account" within ".menu_root"
And   I follow "My account" within ".menu_root"
And   I fill in "user_mail" with "john@doe.com"
And   I click on "Save"
Then  I should see "Account was successfully updated."

@javascript
Scenario: A user is able to change his name if the settings permit it
Given I am admin
And   I open the "Openproject Admin" menu
And   I follow "My account" within ".menu_root"
And   I fill in "user_firstname" with "Jon"
And   I fill in "user_lastname" with "Snow"
And   I click on "Save"
Then  I should see "Account was successfully updated."
