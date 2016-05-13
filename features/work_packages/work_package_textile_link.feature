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

Feature: Work package textile quickinfo links
  Background:
    Given there are the following types:
          | Name      | Is Milestone |
          | Phase     | false        |
          | Milestone | true         |
      And there is 1 user with:
          | login | manager |
      And there is a role "manager"
      And the role "manager" may have the following rights:
          | manage_wiki        |
          | view_wiki_pages    |
          | edit_wiki_pages    |
          | view_work_packages |
      And there is a project named "ecookbook"
      And I am working in project "ecookbook"
      And the project uses the following modules:
          | timelines |
          | wiki      |
      And the user "manager" is a "manager"
      And there are the following issue status:
        | name        | is_closed | is_default |
        | New         | false     | true       |
        | In Progress | false     | false      |
      And there are the following work packages:
        | Subject | Type  | Start date | Due date   | description                | status | responsible | assigned_to |
        | January | None  | 2012-01-01 | 2012-01-31 | Avocado Sali Grande Grande | New    | manager     | manager  |

  @javascript
  Scenario: Adding a work package link
    Given I am already logged in as "manager"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in a 1 hash quickinfo link to "January" for "content_text"
    And I press "Save"
    Then I should see a 1 hash work package quickinfo link to "January" within "div.wiki"
    When I follow the 1 hash work package quickinfo link to "January"
    Then I should see "January" within ".wp-edit-field.subject"
     And I should be on the page of the work package "January"

  @javascript
  Scenario: Adding a work package quickinfo link
    Given I am already logged in as "manager"
    When I go to the wiki page "testitest" for the project called "ecookbook"
     And I fill in a 2 hashes quickinfo link to "January" for "content_text"
     And I press "Save"
    Then I should see a 2 hashes work package quickinfo link to "January" within "div.wiki"
    When I follow the 2 hashes work package quickinfo link to "January"
    Then I should see "January" within ".wp-edit-field.subject"
     And I should be on the page of the work package "January"

  @javascript
  Scenario: Adding a work package quickinfo link with description
    Given I am already logged in as "manager"
    When I go to the wiki page "testitest" for the project called "ecookbook"
     And I fill in a 3 hashes quickinfo link to "January" for "content_text"
     And I press "Save"
    Then I should see a 3 hashes work package quickinfo link to "January" within "div.wiki"
    When I follow the 3 hashes work package quickinfo link to "January"
    Then I should see "January" within ".wp-edit-field.subject"
     And I should be on the page of the work package "January"


  Scenario: Adding a work package quickinfo link without the right to see the work package
    Given there is 1 user with:
        | login | dude |
    And there is a role "dude"
    And the role "dude" may have the following rights:
        | manage_wiki     |
        | view_wiki_pages |
        | edit_wiki_pages |
    And the user "dude" is a "dude"
    And I am already logged in as "dude"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in a 3 hashes quickinfo link to "January" for "content_text"
    And I press "Save"
    Then I should not see a 3 hashes work package quickinfo link to "January" within "div.wiki"
