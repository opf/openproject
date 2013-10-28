#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

Feature: Adding widgets to the page

  Background:
    Given there is 1 project with the following:
      | name        | project1      |
    And there is a role "Admin"
    And there is a role "Manager"
    And I am already Admin
    And I am on the project "project1" overview personalization page

  Scenario: I should see the available widgets
    Then I should see the dropdown of available widgets

  @javascript
  Scenario: Adding a "Watched work packages" widget
   When I select "Watched work packages" from the available widgets drop down
    And I wait for the AJAX requests to finish
    Then the "watched work packages" widget should be in the hidden block
    And "Watched work packages" should be disabled in the my project page available widgets drop down
