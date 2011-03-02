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
            | view_meetings          |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Agenda" within ".meeting_agenda" # I should see the Agenda tab
  
  @javascript
  Scenario: Navigate to a meeting page with a closed agenda
      Given the role "user" may have the following rights:
            | view_meetings          |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Minutes" within ".meeting_minutes" # I should see the Minutes tab

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
