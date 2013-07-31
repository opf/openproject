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

Feature: Timeline View Tests with reporters
	As a Project Member
	I want to view a timeline with many reportings
  Filter the projects on given criteria

  Background:
    Given there are the following types:
          | Name      | Is Milestone | In aggregation |
          | Phase1    | false        | true           |
          | Phase2    | false        | true           |
          | Phase3    | false        | true           |
          | Phase4    | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines           |
          | edit_timelines           |
          | view_planning_elements   |
          | move_planning_elements_to_trash  |
          | delete_planning_elements    |
          | edit_planning_elements      |
          | delete_planning_elements    |
          | view_reportings             |
          | view_project_associations   |

      And there is a project named "ürm" of type "Standard Project"

      And I am working in project "ürm"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And there is a project named "ecookbook0" of type "Standard Project"
      And the project "ecookbook0" has the parent "ürm"

      And I am working in project "ecookbook0"
      And the user "manager" is a "manager"

      And the following types are enabled for projects of type "Standard Project"
          | Phase1    |
          | Phase2    |
          | Phase3    |
          | Phase4    |
          | Milestone |

      And the project uses the following modules:
          | timelines |

      And there are the following planning elements:
              | Subject  | Start date | Due date   | description       | status_name    | responsible    | planning element type |
              | January  | 2012-01-01 | 2012-01-31 | Aioli Grande      | closed         | manager        | Phase1                |
              | February | 2012-02-01 | 2012-02-24 | Aioli Sali        | closed         | manager        | Phase2                |
              | March    | 2012-03-01 | 2012-03-30 | Sali Grande       | closed         | manager        | Phase3                |
              | April    | 2012-04-01 | 2012-04-30 | Aioli Sali Grande | closed         | manager        | Phase4                |


      And there is a project named "ecookbook13" of type "Standard Project"
      And I am working in project "ecookbook13"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And there are the following planning elements:
              | Subject    | Start date | Due date   | description       | status_name    | responsible    |
              | January13  | 2013-01-01 | 2013-01-31 | Aioli Grande      | closed         | manager        |
              | February13 | 2013-02-01 | 2013-02-24 | Aioli Sali        | closed         | manager        |
              | March13    | 2013-03-01 | 2013-03-30 | Sali Grande       | closed         | manager        |
              | April13    | 2013-04-01 | 2013-04-30 | Aioli Sali Grande | closed         | manager        |

      And there is a project named "ecookbookQ3" of type "Extraordinary Project"
      And the following types are enabled for projects of type "Extraordinary Project"
          | Phase1    |
          | Phase2    |
          | Phase3    |
          | Phase4    |
          | Milestone |

      And the project "ecookbookQ3" has the parent "ecookbook13"
      And I am working in project "ecookbookQ3"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And there are the following planning elements:
              | Subject   | Start date | Due date   | description       | status_name    | responsible    |
              | July      | 2012-07-01 | 2013-07-31 | Aioli Grande      | closed         | manager        |
              | August    | 2012-08-01 | 2013-08-31 | Aioli Sali        | closed         | manager        |
              | Septembre | 2012-09-01 | 2013-09-30 | Sali Grande       | closed         | manager        |



      And there is a project named "ecookbookEmpty" of type "Standard Project"
      And I am working in project "ecookbookEmpty"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |


      And  there are the following reportings:
          | Project        | Reporting To Project |
          | ecookbookEmpty | ürm     |
          | ecookbookQ3    | ürm     |
          | ecookbook13    | ürm     |
          | ecookbook0     | ürm     |


      And there are the following project associations:
          | Project A  | Project B   |
          | ecookbook0 | ecookbookQ3 |


      And I am logged in as "manager"

  @javascript
  Scenario: Filter Empty Projects
      When there is a timeline "Testline" for project "ürm"
      And I hide empty projects for the timeline "Testline" of the project called "ürm"

      And I go to the page of the timeline "Testline" of the project called "ürm"
      And I wait for timeline to load table

     Then I should not see the project "ecookbookEmpty"
      And I should see the project "ecookbookQ3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"

  @javascript
  Scenario: Second Level Grouping
    When there is a timeline "Testline" for project "ürm"
      And I set the first level grouping criteria to "ürm" for the timeline "Testline" of the project called "ürm"
      And I set the second level grouping criteria to "Extraordinary Project" for the timeline "Testline" of the project called "ürm"
      And the following types are enabled for projects of type "Extraordinary Project"
          | Phase1    |
          | Phase2    |
          | Phase3    |
          | Phase4    |
          | Milestone |

      And I wait for timeline to load table

     Then I should see the project "ecookbookEmpty"
      And I should see the project "ecookbookQ3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ecookbookQ3" should have an indent of 1
      And the project "ecookbookQ3" should follow after "ecookbook0"

  @javascript
  Scenario: Filter projects by planning element type and timeframe
     Given I am working in the timeline "Testline" of the project called "ürm"
     When there is a timeline "Testline" for project "ürm"
      And I show only projects which have a planning element which lies between "2012-02-01" and "2012-02-31" and has the type "Phase2"
      And I wait for timeline to load table

     Then I should see the project "ecookbook0"
      And I should not see the project "ecookbookEmpty"
      And I should not see the project "ecookbookQ3"
      And I should not see the project "ecookbook13"
      And I should see the planning element "March"
      And I should not see the planning element "August"
      And I should not see the planning element "March13"

  @javascript
  Scenario: First level grouping and sortation
    Given I am working in the timeline "Testline" of the project called "ürm"
    When there is a timeline "Testline" for project "ürm"
      And I set the sortation of the first level grouping criteria to explicit order
      And I set the first level grouping criteria to:
        | ürm         |
        | ecookbook13 |
      And I wait for timeline to load table

    Then I should see the project "ecookbookEmpty"
      And I should see the project "ecookbookQ3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ecookbook13" should follow after "ürm"

  @javascript
  Scenario: First level grouping and sortation
    Given I am working in the timeline "Testline" of the project called "ürm"
    When there is a timeline "Testline" for project "ürm"
      And I set the sortation of the first level grouping criteria to explicit order
      And I set the first level grouping criteria to:
        | ecookbook13 |
        | ürm         |
      And I wait for timeline to load table

    Then I should see the project "ecookbookEmpty"
      And I should see the project "ecookbookQ3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ürm" should follow after "ecookbook13"
