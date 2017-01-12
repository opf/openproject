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

Feature: Viewing the wiki new child page

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
    And the user "bob" is a "member" in the project "project1"
    And I am already logged in as "bob"

  Scenario: Visiting the wiki new child page with a parent page that has the new child page option enabled on it's menu item should show the page and select the toc menu entry within the wiki menu item
    Given the project "project1" has 1 wiki page with the following:
      | title | ParentWikiPage |
    And the project "project1" has 1 wiki menu item with the following:
      | title         | ParentWikiPage |
      | new_wiki_page | true           |
    When I go to the wiki page "ParentWikiPage" of the project called "project1"
    Then I should see "Wiki page" within "#content"

  Scenario: Visiting the wiki new child page with a related page that has the new child page option disabled on it's menu item should show the page and select no menu item
    Given the project "project1" has 1 wiki page with the following:
      | title | ParentWikiPage |
    And the project "project1" has 1 wiki menu item with the following:
      | title      | ParentWikiPage |
    When I go to the wiki new child page below the "ParentWikiPage" page of the project called "project1"
    Then I should see "Wiki page" within "#content"
    And there should be no menu item selected

  Scenario: Visiting the wiki new child page with an invalid parent page
    When I go to the wiki new child page below the "InvalidPage" page of the project called "project1"
    Then I should see "404" within "#content"
    Then I should see "The page you were trying to access doesn't exist or has been removed."
