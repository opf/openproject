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

Feature: Unchanged Member Roles

  @javascript
  Scenario: Global Roles should not be displayed as assignable project roles
    Given there is 1 project with the following:
      | Name       | projectname |
      | Identifier | projectid   |
     And there is a global role "GlobalRole1"
     And there is a role "MemberRole1"
     And I am already admin
    When I go to the members page of the project "projectid"
    And I click "Add member"
    Then I should see "MemberRole1" within "#member_role_ids"
    Then I should not see "GlobalRole1" within "#member_role_ids"
