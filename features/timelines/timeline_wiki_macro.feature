#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Timeline Wiki Macro
  Background:
    Given there are the following types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And there is 1 user with:
          | login | manager |

      And there is 1 user with:
          | login | mrtimeline |

      And there is a role "god"
      And the role "god" may have the following rights:
          | manage_wiki              |
          | view_wiki_pages          |
          | edit_wiki_pages          |
          | view_planning_elements   |
          | edit_planning_elements   |
          | delete_planning_elements |
          | view_timelines           |
      And there is a role "loser"
      And the role "loser" may have the following rights:
          | manage_wiki              |
          | view_wiki_pages          |
          | edit_wiki_pages          |
          | view_planning_elements   |
          | edit_planning_elements   |
          | delete_planning_elements |

      And there is a project named "ecookbook" of type "Standard Project"
      And the following types are enabled for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |
          | wiki      |

      And the user "manager" is a "loser"
      And the user "mrtimeline" is a "god"

      And there are the following planning element statuses:
              | Name     |
              | closed   |
      And there are the following planning elements:
              | Subject  | Start date | Due date   | description         | status_name | responsible |
              | January  | 2012-01-01 | 2012-01-31 | Avocado Grande      | closed      | manager     |
              | February | 2012-02-01 | 2012-02-24 | Avocado Sali        | closed      | manager     |
              | March    | 2012-03-01 | 2012-03-30 | Sali Grande         | closed      | manager     |
              | April    | 2012-04-01 | 2012-04-30 | Avocado Sali Grande | closed      | manager     |
      And there is a timeline "Testline" for project "ecookbook"

  @javascript
  Scenario: Adding a timeline to a wiki
    Given I am already logged in as "mrtimeline"
    When I go to the wiki page "macro_testing" for the project called "ecookbook"
    And I fill in a wiki macro for timeline "Testline" for "content_text"
    And I press "Save"
    And I wait 30 seconds for Ajax
    Then I should see the timeline "Testline"

  Scenario: Adding a timeline with invalid id to a wiki
    Given I am already logged in as "mrtimeline"
    When I go to the wiki page "macro_testing" for the project called "ecookbook"
    And I fill in "{{timeline(38537)}}" for "content_text"
    And I press "Save"
    And I should see "There is no timeline with ID 38537."
    Then I should not see the timeline "Testline"

  Scenario: Adding a timeline without the right to see it
    Given I am already logged in as "manager"
    When I go to the wiki page "macro_testing" for the project called "ecookbook"
    And I fill in a wiki macro for timeline "Testline" for "content_text"
    And I press "Save"
    And I should see "You do not have the necessary permission to view the linked timeline."
    Then I should not see the timeline "Testline"
