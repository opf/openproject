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

Feature: Version Settings of a wiki page

	Background:
     Given there is 1 project with the following:
      		| name       | wikilibs|
      		| identifier | wikilibs|
    And I am already admin
     And the project "wikilibs" has 1 wiki page with the following:
      		| title | lib1 |
     And I go to the wiki index page of the project called "wikilibs"
     And I click "Lib1"
     And I click "Edit"
     And I fill in "content_text" with "Version 1"
     And I press "Save"

@javascript
  Scenario: Overview and see the history of a wiki page

     And I go to the wiki index page of the project called "wikilibs"
     And I click "Lib1"
     And I follow "More functions" within "#content"
     When I click "History"
     Then I should see "History" within "#content"
     When I press "View differences"
     Then I should see "Version 1"
     Then I should see "Version 2"