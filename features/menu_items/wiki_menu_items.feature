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

Feature: Wiki menu items
  Background:
    Given there is 1 project with the following:
      | name        | Awesome Project |
      | identifier  | awesome-project |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_wiki_pages   |
      | edit_wiki_pages   |
      | delete_wiki_pages |
      | manage_wiki_menu  |
    And there is 1 user with the following:
      | login | bob |
    And the user "bob" is a "member" in the project "Awesome Project"
    And the project "Awesome Project" has 1 wiki page with the following:
      | Title | Wiki |
    And the project "Awesome Project" has 1 wiki page with the following:
      | Title | AwesomePage |
    And I am already logged in as "bob"

  @javascript
  Scenario: Adding a main menu entry without index and toc links
    When I go to the wiki page "AwesomePage" for the project called "Awesome Project"
    And I click on "More"
    And I click on "Configure menu item"
    And I fill in "Avocado Wuaärst" for "menu_items_wiki_menu_item_title"
    And I choose "Show as menu item in project navigation"
    And I press "Save"
    And I should see "Avocado Wuaärst" within "#main-menu"

  @javascript @selenium
  Scenario: Adding a main menu entry with index and toc links
    When I go to the wiki page "AwesomePage" for the project called "Awesome Project"
    And I click on "More"
    And I click on "Configure menu item"
    And I fill in "Avocado Wuaärst" for "menu_items_wiki_menu_item_title"
    And I choose "Show as menu item in project navigation"
    And I press "Save"
    When I go to the wiki page "AwesomePage" for the project called "Awesome Project"
    Then I should see "Avocado Wuaärst" within "#main-menu"

  @javascript @selenium
  Scenario: Change existing entry
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    When I click on "More"
    And I click on "Configure menu item"
    And I fill in "Wikikiki" for "menu_items_wiki_menu_item_title"
    And I press "Save"
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    Then I should see "Wikikiki" within "#main-menu"

  @javascript
  Scenario: Do not change existing entry, but saving nonetheless
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    When I click on "More"
    And I click on "Configure menu item"
    And I press "Save"
    Then I should not see "Successful update."

  @javascript
  Scenario: Adding a sub menu entry
    Given the project "Awesome Project" has a wiki menu item with the following:
      | title | SelectMe |
      | name | SelectMe   |
    Given the project "Awesome Project" has a wiki menu item with the following:
      | title | AwesomePage |
      | name | RichtigGeil |
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    When I click on "More"
    And I click on "Configure menu item"
    And I choose "Show as submenu item of"
    When I select "SelectMe" from "parent_wiki_menu_item"
    When I select "RichtigGeil" from "parent_wiki_menu_item"
    And I press "Save"
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    Then I should see "Wiki" within ".menu-children"

  @javascript @selenium
  Scenario: Removing a menu item
    Given the project "Awesome Project" has a wiki menu item with the following:
      | title | DontKillMe |
      | name | DontKillMe  |
    When I go to the wiki page "Wiki" for the project called "Awesome Project"
    When I click on "More"
    And I click on "Configure menu item"
    And I choose "Do not show this wikipage in project navigation"
    And I press "Save"
    Then I should not see "Wiki" within "#main-menu"

  @javascript @selenium
  Scenario: When I delete the last wiki page with a menu item I can select a new menu item and the menu item is replaced
    Given the project "Awesome Project" has a wiki menu item with the following:
      | title | AwesomePage |
      | name  | awesomepage |
    And the wiki menu item of the wiki page "Wiki" of project "Awesome Project" has been deleted
    When I go to the wiki page "awesomepage" for the project called "Awesome Project"
    And I click on "More"
    And I click on "Configure menu item"
    And I choose "Do not show this wikipage in project navigation"
    And I press "Save"
    And I select "Wiki" from "main-menu-item-select"
    And I press "Save"
    Then I should not see "AwesomePage" within "#main-menu"
    Then I should see "Wiki" within "#main-menu"
