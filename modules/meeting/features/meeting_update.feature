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

Feature: Updating meetings

  Background:
        Given there is 1 project with the following:
              | name | worlddomination |
          And the project "worlddomination" uses the following modules:
              | meetings |
          And there is a role "user"
          And the role "user" may have the following rights:
              | view_meetings |
              | edit_meetings |
          And there is 1 user with:
              | login     | alice  |
              | firstname | alice  |
              | lastname  | alice  |
          And there is 1 user with:
              | login     | bob    |
              | firstname | bob    |
              | lastname  | bobbit |
          And there is 1 user with:
              | login     | chuck  |
              | firstname | chuck  |
              | lastname  | testa  |
          And the user "alice" is a "user" in the project "worlddomination"
          And the user "bob" is a "user" in the project "worlddomination"
          And the user "chuck" is a "user" in the project "worlddomination"
          And there is 1 meeting in project "worlddomination" created by "alice" with:
            | title      | Meeting 1           |
            | location   | Room 1              |
            | duration   | 1:30                |
            | start_time | 2011-02-11 12:30:00 |
          And "bob" is invited to the Meeting "Meeting 1"

  Scenario: Adding a new invitee
       When I am already logged in as "alice"
        And I go to the edit page of the meeting called "Meeting 1"
        And I check "chuck testa invited"
        And I click on "Save"
       Then I should see "Successful update."
        And I should see "chuck testa"

  Scenario: Removing an invitee
      When I am already logged in as "alice"
        And I go to the edit page of the meeting called "Meeting 1"
        And I uncheck "bob bobbit invited"
        And I click on "Save"
       Then I should see "Successful update."
        And I should not see "bob bobbit"
