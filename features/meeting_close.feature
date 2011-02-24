Feature: Close existing meetings
  
  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login    | alice |
              | language | en    |
          And there is 1 user with:
              | login | bob |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title | Bobs Meeting |
  
  @javascript
  Scenario: Navigate to a meeting page with no permission to close meetings
      Given the role "user" may have the following rights:
            | view_meetings  |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should not see "Close" within "#meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with permission to close meetings
      Given the role "user" may have the following rights:
            | view_meetings  |
            | close_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Close" within "#meeting_agenda"
  
  @javascript
  Scenario: Navigate to a meeting page with permission to close meetings
      Given the role "user" may have the following rights:
            | view_meetings  |
            | close_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "Close" within "#meeting_agenda"
       Then I should not see "Edit" within "#meeting_agenda"