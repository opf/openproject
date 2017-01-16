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

Feature: Adding and Editing Wiki Tabs

  Background:
    Given there is 1 project with the following:
            | Name | Wookies |
      And the project "Wookies" uses the following modules:
            | wiki |
      And the project "Wookies" has 1 wiki page with the following:
            | Title | wookietest |

  @javascript
  Scenario: Adding simple wiki tab as admin
    Given I am admin
      And I am working in project "Wookies"
      And I go to the wiki index page of the project called "Wookies"

  @javascript
  Scenario: Editing of wiki pages as a member with proper rights
    Given there is 1 user with the following:
            | login | chewbacca|
      And I am logged in as "chewbacca"
      And there is a role "humanoid"
      And the role "humanoid" may have the following rights:
            | view_wiki_pages |
            | edit_wiki_pages |
      And the user "chewbacca" is a "humanoid" in the project "Wookies"
     When I go to the wiki page "wookietest" for the project called "Wookies"
      And I click "Edit"
      And I fill in "content_text" with "testing wookie"
      And I click "Save"
     Then I should see "testing wookie" within "#content"
      And I click "Edit"


  @javascript
  Scenario: Overview and see the history of a wiki page
    Given I am already admin
    Given the wiki page "wookietest" of the project "Wookies" has 3 versions
      And I go to the wiki page "wookietest" for the project called "Wookies"
      And I follow "More" within "#content"
     When I click "History"
     Then I should see "History" within "#content"
     When I press "View differences"
     Then I should see "Version 1/4"
     Then I should see "Version 2/4"
