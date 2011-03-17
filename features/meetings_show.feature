Feature: Show meetings
  
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
  Scenario: Navigate to a meeting page with an open agenda
      Given the role "user" may have the following rights:
            | view_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Agenda" within ".meeting_agenda" # I should see the Agenda tab
        And I should see "No data to display" within ".meeting_agenda"
  
  @javascript
  Scenario: Navigate to a meeting page with a closed agenda
      Given the role "user" may have the following rights:
            | view_meetings |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Minutes" within ".meeting_minutes" # I should see the Minutes tab
        And I should see "No data to display" within ".meeting_minutes"

  @javascript
  Scenario: Navigate to a meeting page with an open agenda and the permission to edit the agenda
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_agendas |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Agenda" within ".meeting_agenda" # I should see the Agenda tab
        And I should not see "No data to display" within "#meeting_agenda-text"
        And I should see "Text formatting" within ".meeting_agenda"
  
  @javascript
  Scenario: Navigate to a meeting page with a closed agenda and the permission to edit the minutes
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_minutes |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Minutes" within ".meeting_minutes" # I should see the Minutes tab
        And I should not see "No data to display" within "#meeting_minutes-text"
        And I should see "Text formatting" within ".meeting_minutes"

  @javascript
  Scenario: Navigate to a meeting page with an open agenda and the permission to edit the minutes
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_minutes |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
            # Make sure we're on the right tab
        And I click on "Minutes"
       Then I should not see "Edit" within ".meeting_minutes"

  @javascript
  Scenario: Navigate to a meeting page with a closed agenda and the permission to edit the agenda
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_agendas |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
            # Make sure we're on the right tab
        And I click on "Agenda"
       Then I should not see "Edit" within ".meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with a closed agenda and the permission to edit the minutes and save minutes
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_minutes |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I fill in "meeting_minutes[text]" with "Some minutes!"
        And I click on "Save"
       Then I should see "Minutes" within ".meeting_minutes" # I should see the Minutes tab
        And I should see "Some minutes!" within "#meeting_minutes-text"
        And I should not see "Text formatting" within "#edit-meeting_minutes"
  
  @javascript
  Scenario: Navigate to a meeting page and view an older version of an agenda
      Given the role "user" may have the following rights:
            | view_meetings |
        And the Meeting "Bobs Meeting" has 1 agenda with:
            | text | blah |
        And the Meeting "Bobs Meeting" has 1 agenda with:
            | text | foo  |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "History"
        And I click on "2"
       Then I should see "Agenda" within ".meeting_agenda" # I should see the Agenda tab
        And I should see "blah" within ".meeting_agenda"
