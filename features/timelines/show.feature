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

Feature: View work packages in a timeline

  Background:
    Given there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines              |
          | view_planning_elements      |

      And there is a project named "ecookbook"

      And I am working in project "ecookbook"

      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And the following types are enabled for the project called "ecookbook":
          | Name      |
          | Phase1    |

      And there are the following planning elements:
        | Subject               | Start date | Due date   | type   |
        | Some planning element | 2012-01-01 | 2012-01-31 | Phase1 |

      And the user "manager" has 1 issue with the following:
        | Subject | Some issue |

      And there is a timeline "Testline" for project "ecookbook"
      And I am already logged in as "manager"

  @javascript
  Scenario: Displaying elements in the timeline
     When I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table

     Then I should see the planning element "Some planning element" in the timeline
     Then I should see the issue "Some issue" in the timeline
