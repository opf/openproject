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

Feature: Searching
  Background:
    Given there is 1 project with the following:
      | identifier | project |
      | name       | test-project |
    And there are the following work packages in project "test-project":
      | subject |
      | wp1     |
    And I am already admin

  @javascript @selenium
  Scenario: Searching stuff retains a project's scope
    When I am on the overview page for the project called "test-project"
     And I search globally for "stuff"
     And I search for "wp1" after having searched
    Then I should see "Overview" within "#main-menu"
     And I click on "wp1" within "#search-results"
    Then I should see "wp1" within ".wp-edit-field.subject"
     And I should be on the page of the work package "wp1"
