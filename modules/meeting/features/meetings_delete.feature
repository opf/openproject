#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
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

Feature: Delete meetings

  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login    | alice |
              | language | en    |
          And there is 1 user with:
              | login    | bob |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "alice" with:
              | title      | Alices Meeting      |
              | location   | Room 1              |
              | duration   | 1:30                |
              | start_time | 2011-02-11 12:30:00 |
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title      | Bobs Meeting        |
              | location   | Room 2              |
              | duration   | 2:30                |
              | start_time | 2011-02-10 11:00:00 |

  Scenario: Navigate to an other-created meeting with no permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should not see "Delete"

  Scenario: Navigate to a self-created meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Alices Meeting"
       Then I should see "Delete"

  Scenario: Navigate to an other-created meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
       Then I should see "Delete"

  @javascript
  Scenario: Delete a meeting with permission to delete meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | delete_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I click on "Delete"
        And I confirm the JS confirm dialog
       Then I should see "Meetings"
        But I should not see "Bobs Meeting"
