Feature: Locking meetings
  
  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login | bob |
          And there is a role "user"
          And the user "bob" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title | Bobs Meeting |
          And the meeting "Bobs Meeting" has 1 agenda
  
  @javascript
  Scenario: Save a meeting after it has changed while editing
      Given the role "user" may have the following rights:
            | view_meetings |
            | create_meetings |
            | create_meeting_agendas |
            | edit_meetings |
       When I login as "bob"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I fill in "Blabla oder?" for "meeting_agenda_text"
       When the agenda of the meeting "Bobs Meeting" changes meanwhile
        And I click on "Save"
       Then I should see "Data has been updated by another user."
       # Prüfen, ob die Editbox noch sichtbar ist 
       # And I should see "Text formatting" within "#tab-content-agenda"
