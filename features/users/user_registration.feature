Feature: User Registration
Background: 
Given I am on the homepage
And I open the "Sign in" menu
And I follow "Register" within "#top-menu-items"
Then I should be on the registration page

@javascript
Scenario: A user can register successfully after filling in the registration form
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Your account was created and is now pending administrator approval."
#And I am already logged in as "admin"
#And I am on the admin page of pending users
#Then I should see "heidi" within ".autoscroll"

@javascript
Scenario: A user is unable to register if one of the constraints left blank
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I click on "Submit"
Then I should see "Email can't be blank"

@javascript
Scenario: A user is unable to register if the password does not match the confirmation
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test1"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Password doesn't match confirmation"
