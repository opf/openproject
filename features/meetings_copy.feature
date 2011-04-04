Feature: Copy meetings
  
  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login    | alice  |
              | language | en     |
          And there is 1 user with:
              | login    | bob    |
          And there is 1 user with:
              | login    | charly |
          And there is 1 user with:
              | login    | dave   |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "alice" with:
              | title    | Alices Meeting |
              | location | CZI            |
              | duration | 1.5            |
  
  @javascript
  Scenario: Navigate to a meeting page with permission to create meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
       Then I should see "Copy" within "#content > .contextual"
  
  @javascript
  Scenario: Navigate to a meeting copy page
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
        And I click on "Copy"
       Then the "meeting[title]" field should contain "Alices Meeting"
        And the "meeting[location]" field should contain "CZI"
        And the "meeting[duration]" field should contain "1.5"
       #And no participant should be selected as attendee
       #And only invited participants should be selected as invitees