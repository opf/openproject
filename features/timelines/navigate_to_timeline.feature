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

Feature: Navigating to the timeline page

  Background:
      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines                  |

      And there is a project named "ecookbook"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am already logged in as "manager"

  Scenario: Navigating to the timeline page via the menu
     When I go to the home page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Timeline reports"
     Then I should be on the new timeline page of the project called "ecookbook"

  Scenario: When navigating via the menu the first timeline is presented by default
     When there is a timeline "Testline" for project "ecookbook"
     When there is a timeline "Testline2" for project "ecookbook"
      And I go to the page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Timeline reports"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"
