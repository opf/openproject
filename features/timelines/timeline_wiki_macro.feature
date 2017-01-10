#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

      And there are the following status:
          | name        | default |
          | new         | true    |
          | in progress | false   |
          | closed      | false   |

    And there is 1 user with:
          | login | manager |

      And there is 1 user with:
          | login | mrtimeline |

      And there is a role "god"
      And the role "god" may have the following rights:
          | manage_wiki          |
          | view_wiki_pages      |
          | edit_wiki_pages      |
          | view_work_packages   |
          | edit_work_packages   |
          | delete_work_packages |
          | view_timelines       |
      And there is a role "loser"
      And the role "loser" may have the following rights:
          | manage_wiki          |
          | view_wiki_pages      |
          | edit_wiki_pages      |
          | view_work_packages   |
          | edit_work_packages   |
          | delete_work_packages |

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

      And there are the following work packages:
          | Subject  | Start date | Due date   | description         | status | responsible |
          | January  | 2012-01-01 | 2012-01-31 | Avocado Grande      | closed | manager     |
          | February | 2012-02-01 | 2012-02-24 | Avocado Sali        | closed | manager     |
          | March    | 2012-03-01 | 2012-03-30 | Sali Grande         | closed | manager     |
          | April    | 2012-04-01 | 2012-04-30 | Avocado Sali Grande | closed | manager     |
      And there is a timeline "Testline" for project "ecookbook"

  @javascript
  Scenario: Adding a timeline to a wiki
    Given I am already logged in as "mrtimeline"
    When I go to the wiki page "macro_testing" for the project called "ecookbook"
    And I fill in a wiki macro for timeline "Testline" for "content_text"
    And I press "Save"
    And I wait for timeline to load table
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
