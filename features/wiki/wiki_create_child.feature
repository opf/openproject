#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

Feature: Create a new child page

	Background:

    Given there is 1 project with the following:
      | name       | wikipeeps|
      | identifier | wikipeeps|
    And the project "wikipeeps" has 1 wiki page with the following:
      | title | Wikiparentpage |
    And there is 1 user with the following:
      | login | todd |
    And there is a role "wiki_admin"
    And the role "wiki_admin" may have the following rights:
      | view_wiki_pages   |
      | edit_wiki_pages   |
      | create_wiki_pages |
      | manage_wiki		  |
    And the user "todd" is a "wiki_admin" in the project "wikipeeps"
    And I am already logged in as "todd"
@javascript
  Scenario: A user with proper rights can add a child wiki page
   
    Given I go to the wiki index page of the project called "wikipeeps"
  	And I click "Wikiparentpage"
  	And I follow "More functions" within "#content"
  	And I click "Create new child page"
  	And I fill in "page_title" with "todd's wiki"
  	And I press "Save"
  	When I go to the wiki index page of the project called "wikipeeps"
  	Then I should see "Todd's wiki" within "#content"