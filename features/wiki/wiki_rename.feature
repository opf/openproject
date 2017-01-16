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

Feature: Renaming a wiki page

  Background:
    Given there is 1 user with the following:
      | login | bob |
    And there is a role "member"
    And the role "member" may have the following rights:
      | view_wiki_pages   |
      | edit_wiki_pages   |
      | rename_wiki_pages |
    And there is 1 project with the following:
      | name       | project1 |
      | identifier | project1 |
    And the user "bob" is a "member" in the project "project1"
    And the project "project1" has 1 wiki page with the following:
      | title | WikiPage |
    And I am already logged in as "bob"

  @javascript
  Scenario: Renaming a wiki page
    When I go to the wiki page "WikiPage" of the project called "project1"
    And I click on "More"
    And I click on "Rename"
    And I fill in "New WikiPage" for "Title"
    And I press "Rename"
    Then I should be on the wiki page "new-wikipage" of the project called "project1"
    And I should see "Successful update." within ".notice"
