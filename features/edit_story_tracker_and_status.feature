Feature: Edit story type and status
  As a user
  I want to edit the type and the status of a story
  In consideration of existing workflows
  So that I can not make changes that are not permitted by the system

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And the following types are configured to track stories:
        | Story |
        | Epic  |
        | Bug   |
    And the type "Task" is configured to track tasks
    And the project uses the following types:
        | Story |
        | Bug   |
        | Task  |
    And there is 1 user with:
        | login | romano |
    And there is a role "manager"
    And the user "romano" is a "manager"
    And the role "manager" may have the following rights:
        | view_master_backlog   |
        | create_stories        |
        | update_stories        |
        | view_work_packages    |
        | edit_work_packages    |
        | manage_subtasks       |
    And the project has the following sprints:
        | name       | start_date | effective_date |
        | Sprint 001 | 2010-01-01 | 2010-01-31     |
    And there are the following issue status:
        | name     | is_closed | is_default |
        | New      | false     | true       |
        | Resolved | false     | false      |
        | Closed   | true      | false      |
        | Rejected | true      | false      |
    And there is a default issuepriority with:
        | name   | Normal |
    And the project has the following stories in the following sprints:
        | subject | sprint     | type | story_points |
        | Story A | Sprint 001 | Bug     | 10           |
        | Story B | Sprint 001 | Story   | 20           |
        | Story C | Sprint 001 | Bug     | 20           |
    And the status of "Story C" is "Resolved"
    And the Tracker "Story" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Rejected   |
        | Rejected   | Closed     |
        | Rejected   | New        |
    And the Tracker "Bug" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Closed     |
    And I am already logged in as "romano"
    And I am on the master backlog

  @javascript
  Scenario: Display only statuses which are allowed by workflow
     When I click on the text "Story A"

    And the available status of the story called "Story A" should be the following:
        | New    |
        | Closed |

    When I select "Closed" from "status_id"
     And I confirm the story form

    Then the displayed attributes of the story called "Story A" should be the following:
        | Status | Closed |

    When I click on the text "Story A"

    Then the available status of the story called "Story A" should be the following:
        | Closed |

  @javascript
  Scenario: Select a status and change to a type that does not offer the status
     When I click on the text "Story B"

     Then the available status of the story called "Story B" should be the following:
        | New      |
        | Rejected |

     When I select "Rejected" from "status_id"
      And I select "Bug" from "type_id"

     Then the editable attributes of the story called "Story B" should be the following:
        | Status | |
     And the available status of the story called "Story B" should be the following:
        | New    |

     When I confirm the story form
     Then the error alert should show "Status can't be blank"

     When I press "OK"
      And I click on the text "Story B"
      And I select "New" from "status_id"
      And I confirm the story form

     Then the displayed attributes of the story called "Story B" should be the following:
        | Status | New |

  @javascript
  Scenario: Edit a story having no permission for the status of the current ticket
     When I click on the text "Story C"

     Then the available status of the story called "Story C" should be the following:
        | New      |
        | Resolved |

     When I confirm the story form

     Then the displayed attributes of the story called "Story C" should be the following:
        | Status | Resolved |
