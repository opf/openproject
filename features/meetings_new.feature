Feature: Create new meetings
  
  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login    | alice |
              | language | en    |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
  
  @javascript
  Scenario: Navigate to the meeting index page with no permission to create new meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
       Then I should not see "New Meeting"
  
  @javascript
  Scenario: Navigate to the meeting index page with permission to create new meetings
            # TODO Rechte werden nicht hinzugefügt sondern ersetzt?
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
       Then I should see "New Meeting"
  
  @javascript
  Scenario: Create a new meeting with no title
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
        And I click on "Create"
            # TODO Gibt's eine bessere Möglichkeit validation errors abzufragen?
       Then I should see "Title can't be blank"
  
  @javascript
  Scenario: Create a new meeting with no title
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
        And I fill in the following:
            | meeting_title | FSR Sitzung 123 |
        And I click on "Create"
       Then I should see "Successful creation."
        And I should see "FSR Sitzung 123"
            # TODO sollten hier noch die "Defaults" abgefragt werden? Wahrscheinlich eher eine RSpec Sache?
  
  @javascript
  Scenario: The start-time should be selectable in 5-minute increments
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
       Then I should see "New Meeting"
        And I should not see "01" within "#meeting_start_time_5i"
        And I should not see "14" within "#meeting_start_time_5i"
            # TODO entweder ich habe einen Knick in der Optik, oder die beiden sollten klappen, geht aber auch mit den 2 nächsten Zeilen...
       #And "00" should be selectable from "meeting_start_time_5i"
       #And "05" should be selectable from "meeting_start_time_5i"
        And I should see "00" within "#meeting_start_time_5i"
        And I should see "05" within "#meeting_start_time_5i"