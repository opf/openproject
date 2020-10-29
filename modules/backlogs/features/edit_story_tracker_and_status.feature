#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

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
        | view_work_packages    |
        | add_work_packages     |
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
        | subject | sprint     | type  | status | story_points |
        | Story A | Sprint 001 | Bug   | New    | 10           |
        | Story B | Sprint 001 | Story | New    | 20           |
        | Story C | Sprint 001 | Bug   | New    | 20           |
    And the Type "Story" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Rejected   |
        | Rejected   | Closed     |
        | Rejected   | New        |
    And the Type "Bug" has for the Role "manager" the following workflows:
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
     When the Type "Bug" has for the Role "manager" the following workflows:
        | old_status | new_status |
        | New        | Resolved   |
      And I am on the master backlog
      And I click on the text "Story C"

     Then the available status of the story called "Story C" should be the following:
        | New      |
        | Resolved |

     When I select "Resolved" from "status_id"
      And I confirm the story form

     Then the displayed attributes of the story called "Story C" should be the following:
        | Status | Resolved |
