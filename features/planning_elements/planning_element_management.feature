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

Feature: Planning Element Management
  As a Project Member
  I want to view and edit planning elements within a project
  So that I can plan the project's progress and report it to other projects

  Background:
    Given there are the following planning element types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And the following types are default for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines           |
          | view_planning_elements   |
          | edit_planning_elements   |
          | delete_planning_elements |
          | view_work_packages       |
          | add_work_packages        |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am logged in as "manager"

  Scenario: The project manager gets 'No data to display' when there are no planning elements defined
     When I go to the   page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Planning elements"
     Then I should see "No data to display"
      And I should see "New planning element"

  Scenario: The project manager may create planning elements
     When I go to the   page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Planning elements"
      And I follow "New planning element"
      And I fill in "February" for "Subject"
      And I fill in "2012-02-01" for "Start date"
      And I fill in "2012-02-29" for "End date"
      And I submit the form by the "Create" button
     Then I should see a notice flash stating "Successful creation."
      And I should see "February"

     When I toggle the "Timelines" submenu
      And I follow "Planning elements"
     Then I should see a planning element named "February"

     When I follow "Activity"
     Then I should see "Creation: February"

  Scenario: The project manager may edit planning elements
    Given there are the following planning elements:
            | Subject  | Start date | Due date   |
            | January  | 2012-01-01 | 2012-01-31 |
            | February | 2012-02-01 | 2012-02-29 |
            | March    | 2012-03-01 | 2012-03-31 |
     When I go to the page of the planning element "February" of the project called "ecookbook"
     When I click on "Update" within "#content > .action_menu_main"
      And I fill in "February 2012" for "Subject"
      And I press "Save"
     Then I should see a notice flash stating "Successful update."

     When I toggle the "Timelines" submenu
      And I follow "Planning elements"
     Then I should see a planning element named "February 2012"

     When I follow "Activity"
     Then I should see "Creation: February 2012"
     Then I should see "Update: February 2012"

  Scenario: Editing a scenario
    Given there are the following planning elements:
            | Subject  | Start date | Due date   |
            | January  | 2012-01-01 | 2012-01-31 |
    Given there is a scenario "worst case" in project "ecookbook"
      And there are the following alternate dates for "worst case":
            | Planning element subject  | Start date | Due date   |
            | January                   | 2013-01-01 | 2013-01-31 |
     When I go to the page of the planning element "January" of the project called "ecookbook"
     When I click on "Update" within "#content > .action_menu_main"
     When I fill in "2012-02-01" for "worst case Start date"
      And I fill in "2012-02-29" for "worst case End date"
      And I press "Save"
     Then I should see "Scenario worst case: Start date changed from 01/01/2013 to 02/01/2012"
      And I should see "Scenario worst case: Due date changed from 01/31/2013 to 02/29/2012"

  Scenario: Deleting a scenario that is associated to a planning element
    Given there are the following planning elements in project "ecookbook":
            | Subject  | Start date | Due date   |
            | January  | 2012-01-01 | 2012-01-31 |
    And there is a scenario "delete me" in project "ecookbook"
    And there are the following alternate dates for "delete me":
            | Planning element subject  | Start date | Due date   |
            | January                   | 2013-01-01 | 2013-01-31 |
     When I go to the   page of the project called "ecookbook"
      And I toggle the "Timelines" submenu
      And I follow "Planning elements"
     Then I should see a planning element named "January"
     When I delete the scenario "delete me"
      And I follow "January" within ".timelines-pe-name"
     Then I should see "Scenario (deleted scenario): Start date set to 01/01/2013"
      And I should see "Scenario (deleted scenario): Due date set to 01/31/2013"
