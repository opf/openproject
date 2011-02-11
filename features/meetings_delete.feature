Feature: Delete meetings
  
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
              | login    | bob |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title      | Alices Meeting      |
              | location   | Room 1              |
              | duration   | 1:30                |
              | start_time | 2011-02-11 12:30:00 |
          And there is 1 meeting in project "dingens" created by "alice" with:
              | title      | Bobs Meeting        |
              | location   | Room 2              |
              | duration   | 2:30                |
              | start_time | 2011-02-10 11:00:00 |
  
  @javascript
  Scenario: Navigate to an other-created meeting with no permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should not see "Delete"
  
  @javascript
  Scenario: Navigate to a self-created meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
       Then I should see "Delete"
  
  @javascript
  Scenario: Navigate to an other-created meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Delete"
  
  @javascript
  Scenario: Delete an other-created meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I login as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
            # TODO Wie kriegt man das hin?
            # Momentan bleibt das bei mir beim javascript "confirm" Dialog hängen
        #And I click on "Delete"
       Then I should see "Meetings"
        But I should not see "Bobs Meeting"