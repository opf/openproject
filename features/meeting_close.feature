Feature: Close and open meeting angedas
  
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
  Scenario: Navigate to a meeting page with no permission to close meeting agendas
      Given the role "user" may have the following rights:
            | view_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should not see "Close" within ".meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with permission to close and close the meeting agenda
      Given the role "user" may have the following rights:
            | view_meetings         |
            | close_meeting_agendas |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "Close"
       Then I should not see "Close" within ".meeting_agenda"
        And I should see "Open" within ".meeting_agenda"
  
  @javascript
  Scenario: Navigate to a meeting page with permission to close and open the meeting agenda
      Given the role "user" may have the following rights:
            | view_meetings         |
            | close_meeting_agendas |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "Open"
       Then I should not see "Open" within ".meeting_agenda"
        And I should see "Close" within ".meeting_agenda"
  
  @javascript
  Scenario: Navigate to a  meeting page with a closed meeting agenda and permission to edit meeting agendas
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_agendas |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should not see "Edit" within ".meeting_agenda"