#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

      And there are the following status:
          | name        | default |
          | new         | true    |
          | in progress | false   |
          | closed      | false   |

      And there is 1 user with:
          | login | manager |

      And there is 1 user with:
          | Login     |martymcfly |
          | Firstname | Marty     |
          | Lastname  | McFly     |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines            |
          | edit_timelines            |
          | view_work_packages        |
          | edit_work_packages        |
          | delete_work_packages      |
          | view_reportings           |
          | view_project_associations |

      And there is a project named "ecookbook" of type "Standard Project"

      And I am working in project "ecookbook"

      And the user "manager" is a "manager"
      And the user "martymcfly" is responsible

      And the project uses the following modules:
          | timelines |

      And there is a project named "ecookbook0" of type "Standard Project"
      And the project "ecookbook0" has the parent "ecookbook"

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

      And there are the following work packages:
          | Subject  | Start date | Due date   | description       | status | responsible | type   |
          | January  | 2012-01-01 | 2012-01-31 | Aioli Grande      | closed | manager     | Phase1 |
          | February | 2012-02-01 | 2012-02-24 | Aioli Sali        | closed | manager     | Phase2 |
          | March    | 2012-03-01 | 2012-03-30 | Sali Grande       | closed | manager     | Phase3 |
          | April    | 2012-04-01 | 2012-04-30 | Aioli Sali Grande | closed | manager     | Phase4 |

      And there is a project named "ecookbook13" of type "Standard Project"
      And I am working in project "ecookbook13"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And there are the following work packages:
          | Subject    | Start date | Due date   | description       | status | responsible |
          | None       |            |            | Aioli Sali        | closed | manager     |
          | January13  | 2013-01-01 | 2013-01-31 | Aioli Grande      | closed | manager     |
          | February13 | 2013-02-01 | 2013-02-24 | Aioli Sali        | closed | manager     |
          | March13    | 2013-03-01 | 2013-03-30 | Sali Grande       | closed | manager     |
          | April13    | 2013-04-01 | 2013-04-30 | Aioli Sali Grande | closed | manager     |

      And there is a project named "ecookbook_q3" of type "Extraordinary Project"
      And the following types are enabled for projects of type "Extraordinary Project"
          | Phase1    |
          | Phase2    |
          | Phase3    |
          | Phase4    |
          | Milestone |

      And the project "ecookbook_q3" has the parent "ecookbook13"
      And I am working in project "ecookbook_q3"
      And the user "manager" is a "manager"
      And the user "martymcfly" is responsible

      And the project uses the following modules:
          | timelines |

      And there are the following work packages:
          | Subject   | Start date | Due date   | description  | status | responsible |
          | None      |            |            | Aioli Sali   | closed | manager     |
          | July      | 2013-07-01 | 2013-07-31 | Aioli Grande | closed | manager     |
          | August    | 2012-08-01 | 2013-08-31 | Aioli Sali   | closed | manager     |
          | Septembre | 2012-09-01 | 2013-09-30 | Sali Grande  | closed | manager     |

      And there is a project named "ecookbook_empty" of type "Standard Project"
      And I am working in project "ecookbook_empty"
      And the user "manager" is a "manager"

      And the project uses the following modules:
          | timelines |

      And  there are the following reportings:
          | Project         | Reporting To Project |
          | ecookbook_empty | ecookbook            |
          | ecookbook_q3    | ecookbook            |
          | ecookbook13     | ecookbook            |
          | ecookbook0      | ecookbook            |

      And there are the following project associations:
          | Project A  | Project B    |
          | ecookbook0 | ecookbook_q3 |

      And I am already logged in as "manager"

  @javascript
  Scenario: Filter Empty Projects
      When there is a timeline "Testline" for project "ecookbook"
      And I hide empty projects for the timeline "Testline" of the project called "ecookbook"

      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
     Then I should not see the project "ecookbook_empty"
      And I should see the project "ecookbook_q3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"

  @javascript
  Scenario: Second Level Grouping
    When there is a timeline "Testline" for project "ecookbook"
      And I set the first level grouping criteria to "ecookbook" for the timeline "Testline" of the project called "ecookbook"
      And I set the second level grouping criteria to "Extraordinary Project" for the timeline "Testline" of the project called "ecookbook"
      And the following types are enabled for projects of type "Extraordinary Project"
          | Phase1    |
          | Phase2    |
          | Phase3    |
          | Phase4    |
          | Milestone |
      And I wait for timeline to load table

     Then I should see the project "ecookbook_empty"
      And I should see the project "ecookbook_q3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ecookbook_q3" should have an indent of 1
      And the project "ecookbook_q3" should follow after "ecookbook0"

  @javascript
  Scenario: Filter projects by planning element type and timeframe
     Given I am working in the timeline "Testline" of the project called "ecookbook"

     When there is a timeline "Testline" for project "ecookbook"
      And I show only projects which have a planning element which lies between "2012-02-01" and "2012-02-27" and has the type "Phase2"
      And I wait for timeline to load table

     Then I should see the project "ecookbook0"
      And I should not see the project "ecookbook_empty"
      And I should not see the project "ecookbook_q3"
      And I should not see the project "ecookbook13"
      And I should see the work package "March" in the timeline
      And I should not see the work package "August" in the timeline
      And I should not see the work package "March13" in the timeline

  @javascript
  Scenario: Filter projects by responsible
     Given I am working in the timeline "Testline" of the project called "ecookbook"

     When there is a timeline "Testline" for project "ecookbook"
      And I show only projects which have responsible set to "martymcfly"
      And I wait for timeline to load table

     Then I should see the project "ecookbook"
      And I should see the project "ecookbook_q3"
      And I should not see the project "ecookbook_empty"
      And I should not see the project "ecookbook13"
      And I should see the work package "July" in the timeline
      And I should see the work package "August" in the timeline

  @javascript
  Scenario: First level grouping and sortation
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the sortation of the first level grouping criteria to explicit order
      And I set the first level grouping criteria to:
        | ecookbook   |
        | ecookbook13 |
      And I wait for timeline to load table

     Then I should see the project "ecookbook_empty"
      And I should see the project "ecookbook_q3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ecookbook13" should follow after "ecookbook"

  @javascript
  Scenario: First level grouping and sortation
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the sortation of the first level grouping criteria to explicit order
      And I set the first level grouping criteria to:
        | ecookbook13 |
        | ecookbook   |
      And I wait for timeline to load table

     Then I should see the project "ecookbook_empty"
      And I should see the project "ecookbook_q3"
      And I should see the project "ecookbook13"
      And I should see the project "ecookbook0"
      And the project "ecookbook" should follow after "ecookbook13"

  @javascript
  Scenario: First level grouping and hide other
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I set the first level grouping criteria to:
        | ecookbook   |
        | ecookbook13 |
      And I enable the hide other group option
      And I wait for timeline to load table

     Then I should not see the project "ecookbook_empty"
      And I should see the project "ecookbook_q3"
      And I should see the project "ecookbook0"
      And the project "ecookbook13" should follow after "ecookbook"

  @javascript
  Scenario: First level grouping and sortation
    Given I am working in the timeline "Testline" of the project called "ecookbook"
    When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table

     Then the project "ecookbook13" should follow after "ecookbook_q3"
      And the project "ecookbook_q3" should follow after "ecookbook0"
      And the project "ecookbook0" should follow after "ecookbook_empty"
