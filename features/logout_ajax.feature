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

Feature: Doing Ajax when logged out
  Background:
      And there is 1 user with:
          | login | manager |

      And there are the following project types:
          | Name                  |
          | Standard Project      |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines         |
          | edit_timelines         |
          | view_planning_elements |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am logged in as "manager"

      And there are the following planning elements:
              | Subject  | Start date | Due date   | description       | status_name    | responsible    |
              | January  | 2012-01-01 | 2012-01-31 | Aioli Grande      | closed         | manager        |

  @javascript
  Scenario: If we do ajax while being logged out a confirm dialog should open
    Given there is a timeline "Testline" for project "ecookbook"
    When I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I log out in the background
      And I open a modal for planning element "January" of project "ecookbook"
      And I confirm popups
    Then I should be on the login page
