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

Feature: Show meeting activity

  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
              | activity |
          And there is 1 user with:
              | login    | alice |
              | language | en    |
              | admin    | true  |
          And there is a role "user"
          And the role "user" may have the following rights:
              | view_meetings |
              | edit_meetings |
          And the user "alice" is a "user" in the project "dingens"
          And the user "alice" has the following preferences
              | time_zone | UTC |
          And there is 1 user with:
              | login    | bob |
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title      | Bobs Meeting        |
              | location   | Room 2              |
              | duration   | 2.5                 |
              | start_time | 2011-02-10 11:00:00 |
          And the meeting "Bobs Meeting" has 1 agenda with:
              | locked | true   |
              | text   | foobaz |
          And the meeting "Bobs Meeting" has minutes with:
              | text   | barbaz |
          And I am already logged in as "alice"

  Scenario: Navigate to the project's activity page and see the meeting activity
       When I go to the meetings activity page for the project "dingens"
        And I activate activity filter "Meetings"
       When I click "Apply"
       Then I should see "Meeting: Bobs Meeting (02/10/2011 11:00 AM-01:30 PM)" within "li.meeting a"
        And I should see "Agenda: Bobs Meeting" within ".meeting-agenda"
        And I should see "Minutes: Bobs Meeting" within ".meeting-minutes"

  Scenario: Change a metadata on a meeting and see the activity on the project's activity page
       When I go to the edit page for the meeting called "Bobs Meeting"
        And I fill in the following:
            | meeting_location | Geheimer Ort! |
        And I press "Save"
        And I go to the meetings activity page for the project "dingens"
        And I activate activity filter "Meetings"
       When I click "Apply"
       Then I should see "Meeting: Bobs Meeting (02/10/2011 11:00 AM-01:30 PM)" within ".meeting.me"
