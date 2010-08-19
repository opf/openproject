Feature: Product Owner
  As a product owner
  I want to manage stories
  So that they get done according to my needs

  Background:
    Given the ecookbook project has the backlogs plugin enabled
    And I am a product owner of the ecookbook project
    And the ecookbook project has the following sprints:
      | name       | sprint_start_date | effective_date |
      | sprint 001 | 2010-01-01        | 2010-01-31     |
      | sprint 002 | 2010-02-01        | 2010-02-28     |
      | sprint 003 | 2010-03-01        | 2010-03-31     |

  Scenario: View the product backlog
    Given I am viewing the ecookbook master backlog
    Then I should see the product backlog

  Scenario: Move a story to the top
    Given I am viewing the ecookbook master backlog
    When I move the 3rd story to the 1st position
    Then the story should be at the top