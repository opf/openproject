#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Feature: No Module

  Scenario: Global Rights Modules do not exist as Project -> Settings -> Modules
    Given there is the global permission "glob_test" of the module "global"
    And there is 1 project with the following:
      | name       | test |
      | identifier | test |
    And I am already admin
    When I go to the members tab of the settings page for the project "test"
    Then I should not see "Global"
