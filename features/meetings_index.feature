Feature: Show existing meetings
  
  # TODO Wie geht das genau?
  #Before do
  #  Given there is 1 project with the following:
  #    | identifier | dingens |
  #    | name       | dingens |
  #  And the project "dingens" uses the following modules:
  #    | meetings |
  #  And there is 1 user with:
  #    | login    | alice |
  #    | language | en    |
  #end

  @javascript
  Scenario: Navigate to the meeting index page with no meetings
    Given there is 1 project with the following:
      | identifier | dingens |
      | name       | dingens |
    And the project "dingens" uses the following modules:
      | meetings |
    And there is 1 user with:
      | login    | alice |
      | language | en    |
    Given there is a role "user"
    And the role "user" may have the following rights:
      | view_meetings |
    And the user "alice" is a "user" in the project "dingens"
    When I login as "alice"
    And I go to the page for the project "dingens"
    And I click on "Meetings"
    Then I should see "Meetings" within "#content"
    And I should see "No data to display" within "#content"
    
  @javascript
  Scenario: Navigate to the meeting index page with 2 meetings
    Given there is 1 project with the following:
      | identifier | dingens |
      | name       | dingens |
    And the project "dingens" uses the following modules:
      | meetings |
    And there is 1 user with:
      | login    | alice |
      | language | en    |
    Given there is a role "user"
    And the role "user" may have the following rights:
      | view_meetings |
    And the user "alice" is a "user" in the project "dingens"
    And there is 1 meeting in project "dingens" created by "alice" with:
      | title      | Meeting 1           |
      | location   | Room 1              |
      | duration   | 1:30                |
      | start_time | 2011-02-11 12:30:00 |
    And there is 1 meeting in project "dingens" created by "alice" with:
      | title      | Meeting 2           |
      | location   | Room 2              |
      | duration   | 2:30                |
      | start_time | 2011-02-10 11:00:00 |
    When I login as "alice"
    And I go to the page for the project "dingens"
    And I click on "Meetings"
    Then I should see "Meetings" within "#content"
    And I should not see "No data to display" within "#content"
    And I should see 2 meetings