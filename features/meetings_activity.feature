Feature: Show meeting activity
  
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
          And the role "user" may have the following rights:
              | view_meetings |
              | edit_meetings |
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 user with:
              | login    | bob |
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title      | Bobs Meeting        |
              | location   | Room 2              |
              | duration   | 2.5                 |
              | start_time | 2011-02-10 11:00:00 |
          And the meeting "Bobs Meeting" has 1 agenda with:
              | locked | true   |
              | text   | foobaz |
          And the meeting "Bobs Meeting" has minutes with:
              | text   | barbaz |
  
  @javascript
  Scenario: Navigate to the project's activity page and see the meeting activity
       When I login as "alice"
        And I go to the activity page for the project called "dingens"
        And I click on "Meetings"
       Then I should see "Meeting: Bobs Meeting (02/10/2011 11:00 am-01:30 pm)" within ".meeting"
        And I should see "Agenda: Bobs Meeting" within ".meeting-agenda"
        And I should see "Minutes: Bobs Meeting" within ".meeting-minutes"

  @javascript
  Scenario: Change a metadata on a meeting and see the activity on the project's activity page
       When I login as "alice"
        And I go to the meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "Edit"
        And I fill in the following:
            | meeting_location | Geheimer Ort! |
        And I click on "Save"
        And I go to the activity page for the project called "dingens"
        And I click on "Meetings"
       Then I should see "Meeting: Bobs Meeting (02/10/2011 11:00 am-01:30 pm)" within ".meeting.me"