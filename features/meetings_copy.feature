Feature: Copy meetings
  
  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login     | alice  |
              | language  | en     |
              | firstname | Alice  |
              | lastname  | Alice  |
          And there is 1 user with:
              | login     | bob    |
          And there is 1 user with:
              | login     | charly |
          And there is 1 user with:
              | login     | dave   |
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
  
  @javascript
  Scenario: Navigate to a meeting copy page to make sure the author is selected as invited but not as attendee
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
        And "alice" attended the Meeting "Alices Meeting"
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
        And I click on "Copy"
       Then the "meeting[participants_attributes][][invited]" checkbox should be checked
        And the "meeting[participants_attributes][][attended]" checkbox should not be checked
  
  @javascript
  Scenario: Copy a meeting and make sure the author isn''t copied over
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
        And I click on "Copy"
        And I click on "Create"
       Then I should not see "Alice Alice; Alice Alice"
        And I should see "Alice Alice"
  
  @javascript
  Scenario: Copy a meeting and make sure the agenda ist copied over
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
        And the meeting "Alices Meeting" has 1 agenda with:
            | text | "blubber" |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
        And I click on "Copy"
        And I click on "Create"
        And I click on "Agenda"
        And I click on "History"
       Then I should see "Copied from Meeting #"