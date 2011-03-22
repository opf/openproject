Feature: Search meetings through the global search
  
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
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 user with:
              | login    | bob |
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title      | Bobs Meeting        |
              | location   | Room 2              |
              | duration   | 2:30                |
              | start_time | 2011-02-10 11:00:00 |
          And the meeting "Bobs Meeting" has 1 agenda with:
              | locked | true   |
              | text   | foobaz |
          And the meeting "Bobs Meeting" has minutes with:
              | text   | barbaz |
  
  @javascript
  Scenario: Navigate to the search page and search for a meeting
       When I login as "alice"
        And I go to the search page
        And I fill in the following:
            | search-input | bob |
        And I click on "Submit"
       Then I should see "Bobs Meeting" within "#search-results .meeting"
