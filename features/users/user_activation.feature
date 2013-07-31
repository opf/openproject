 Feature:User Activation

 @javascript

Scenario: An admin could activate the pending registration request
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Your account was created and is now pending administrator approval."
And I am already logged in as "admin"
And I am on the admin page of pending users
Then I should see "heidi" within ".autoscroll"


@javascript
Scenario: An admin activates the pending registration request
Given I am on the registration page
And I fill in "user_login" with "heidi"
And I fill in "user_password" with "test123456T?"
And I fill in "user_password_confirmation" with "test123456T?"
And I fill in "user_firstname" with "Heidi"
And I fill in "user_lastname" with "Swiss"
And I fill in "user_mail" with "heidi@heidiland.com"
And I click on "Submit"
Then I should see "Your account was created and is now pending administrator approval."
And I am already logged in as "admin"
And I am on the admin page of pending users
When I follow "Activate" within ".autoscroll"
Then I should see "Successful update"
