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

Feature: Creating a wiki child page

  Background:
    Given there are no wiki menu items
    And there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_wiki_pages   |
      | edit_wiki_pages   |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
      | name       | project1 |
    And the user "bob" is a "member" in the project "project1"
    And I am already logged in as "bob"

  @javascript
  Scenario: A user with proper rights can add a child wiki page
    Given the project "project1" has 1 wiki page with the following:
      | title | Wikiparentpage |
    Given I go to the wiki index page of the project called "project1"
      And I click "Wikiparentpage"
      And I click "Wiki page"
      And I fill in "content_page_title" with "Todd's wiki"
      And I press "Save"
    When I go to the wiki index page of the project called "project1"
    Then I should see "Todd's wiki" within "#content"

  @javascript
  Scenario: Creating a wiki child page the title of which contains special characters
    Given the project "project1" has 1 wiki page with the following:
      | title | ParentWikiPage |
    And the project "project1" has 1 wiki menu item with the following:
      | title         | ParentWikiPage |
      | new_wiki_page | true           |
    When I go to the wiki page "ParentWikiPage" of the project called "project1"
    And I click "Wiki page"
    And I fill in "content_page_title" with "Child Page !@#{$%^&*()_},./<>?;':"
    And I click "Save"
    Then I should see "Successful creation."
