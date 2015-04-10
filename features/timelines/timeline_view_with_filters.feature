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

Feature: Timeline view with filter tests
	As an openproject user
	I want to view filtered timelines

  Background:
    Given there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines     |
          | edit_timelines     |
          | view_work_packages |

      And there are the following project types:
          | Name  |
          | Pilot |

      And there is a project named "Space Pilot 3000" of type "Pilot"
      And I am working in project "Space Pilot 3000"
      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"
      And I am already logged in as "manager"
      And there are the following types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And the following types are enabled for projects of type "Pilot"
          | Phase     |
          | Milestone |
      And there is a timeline "Storyboard" for project "Space Pilot 3000"


  @javascript
  Scenario: The timeline w/o filters renders properly
    Given there are the following work packages in project "Space Pilot 3000":
          | Subject                  | Start date | Due date   | Type  | Parent |
          | Mission to the moon      | 3000-01-02 | 3000-01-03 | Phase |        |
          | Mom captures Nibblonians | 3000-04-01 | 3000-04-13 | Phase |        |

     When I go to the page of the timeline of the project called "Space Pilot 3000"
      And I wait for timeline to load table
     Then I should see the work package "Mission to the moon" in the timeline
      And I should see the work package "Mom captures Nibblonians" in the timeline

  @javascript
  Scenario: The timeline w/ type filters renders properly
    Given there are the following work packages in project "Space Pilot 3000":
          | Subject                             | Start date | Due date   | Type      | Parent      |
          | Hubert Farnsworth's Birthday        | 2841-04-09 | 2841-04-09 | Milestone |             |
          | Second year                         | 3000-01-01 | 3000-01-05 | Phase     |             |
          | Hubert Farnsworth's second Birthday | 2842-04-09 | 2842-04-09 | Milestone | Second year |
          | Hubert Farnsworth's third Birthday  | 2843-04-09 | 2843-04-09 | Milestone | Second year |
      And I am working in the timeline "Storyboard" of the project called "Space Pilot 3000"
     When I go to the page of the timeline of the project called "Space Pilot 3000"
      And I show only work packages which have the type "Milestone"
      And I wait for timeline to load table
     Then I should see the work package "Hubert Farnsworth's Birthday" in the timeline
     Then I should see the work package "Hubert Farnsworth's second Birthday" in the timeline
     Then I should see the work package "Hubert Farnsworth's third Birthday" in the timeline
      And I should not see the work package "Second year" in the timeline

  @javascript
  Scenario: The timeline w/ responsibles filters renders properly
    Given there is 1 user with:
          | Login     | hubert     |
          | Firstname | Hubert     |
          | Lastname  | Farnsworth |
      And there are the following work packages in project "Space Pilot 3000":
          | Subject                             | Start date | Due date   | Responsible | Parent      |
          | Hubert Farnsworth's Birthday        | 2841-04-09 | 2841-04-09 | hubert      |             |
          | Second year                         | 3000-01-01 | 3000-01-05 |             |             |
          | Hubert Farnsworth's second Birthday | 2842-04-09 | 2842-04-09 | hubert      | Second year |
          | Hubert Farnsworth's third Birthday  | 2843-04-09 | 2843-04-09 | hubert      | Second year |
      And I am working in the timeline "Storyboard" of the project called "Space Pilot 3000"
     When I go to the page of the timeline of the project called "Space Pilot 3000"
      And I show only work packages which have the responsible "hubert"
      And I wait for timeline to load table
     Then I should see the work package "Hubert Farnsworth's Birthday" in the timeline
      And I should see the work package "Hubert Farnsworth's second Birthday" in the timeline
      And I should see the work package "Hubert Farnsworth's third Birthday" in the timeline
      And I should not see the work package "Second year" in the timeline

  @javascript
  Scenario: The timeline w/ responsibles filters renders properly
    Given there is 1 user with:
          | Login     | hubert     |
          | Firstname | Hubert     |
          | Lastname  | Farnsworth |
      And there are the following work packages in project "Space Pilot 3000":
          | Subject                             | Start date | Due date   | Responsible | Parent      |
          | Hubert Farnsworth's Birthday        | 2841-04-09 | 2841-04-09 | hubert      |             |
          | Second year                         | 3000-01-01 | 3000-01-05 |             |             |
          | Hubert Farnsworth's second Birthday | 2842-04-09 | 2842-04-09 | hubert      | Second year |
          | Hubert Farnsworth's third Birthday  | 2843-04-09 | 2843-04-09 | hubert      | Second year |
      And I am working in the timeline "Storyboard" of the project called "Space Pilot 3000"
     When I go to the page of the timeline of the project called "Space Pilot 3000"
      And I show only work packages which have no responsible
      And I wait for timeline to load table
     Then I should not see the work package "Hubert Farnsworth's Birthday" in the timeline
      And I should not see the work package "Hubert Farnsworth's second Birthday" in the timeline
      And I should not see the work package "Hubert Farnsworth's third Birthday" in the timeline
      And I should see the work package "Second year" in the timeline

