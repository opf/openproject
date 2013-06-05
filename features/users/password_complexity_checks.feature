Feature: Password Complexity Checks
    Scenario: A user changing the password including attempts to set not complex enough passwords
        Given passwords must contain 2 of lowercase, uppercase, and numeric characters
        And passwords have a minimum length of 4 characters
        And I am logged in
        And I try to set my new password to "password"
        Then there should be an error describing the password complexity is too low
        When I try to set my new password to "Password"
        Then the password change should succeed
        And I should be able to login using the new password

    Scenario: An admin can change the password complexity requirements and they are effective
        Given I am admin
        When I visit the authentication settings page
        And I activate the lowercase, uppercase, and special password rules
        And I fill in "Minimum number of rules to adhere to" with "3"
        And I save the settings
        And I try to set my new password to "adminADMIN"
        Then there should be an error describing the password complexity is too low
        And I try to set my new password to "adminADMIN123"
        Then there should be an error describing the password complexity is too low
        And I try to set my new password to "adminADMIN!"
        Then the password change should succeed
