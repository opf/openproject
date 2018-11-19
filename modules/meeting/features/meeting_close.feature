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

Feature: Close and open meeting agendas

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
              | login | bob |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title | Bobs Meeting |

  @javascript
  Scenario: Navigate to a meeting page with no permission to close meeting agendas
      Given the role "user" may have the following rights:
            | view_meetings |
       When I am already logged in as "alice"
        And I go to the show page of the meeting called "Bobs Meeting"
        And I follow "Agenda"
       Then I should not see "Close" within ".meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with permission to close the meeting agenda and go to the minutes
      Given the role "user" may have the following rights:
            | view_meetings         |
            | close_meeting_agendas |
       When I am already logged in as "alice"
        And I go to the show page of the meeting called "Bobs Meeting"
        And I follow "Minutes" within ".tabs"
       Then I should not see "Edit" within ".meeting_minutes"
        And I should see "Close the agenda to begin the Minutes" within ".meeting_minutes"

  @javascript
  Scenario: Navigate to a meeting page with permission to close and close the meeting agenda copies the text and shows the meeting
      Given the role "user" may have the following rights:
            | view_meetings         |
            | close_meeting_agendas |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | text | "blubber" |
       When I am already logged in as "alice"
        And I go to the show page of the meeting called "Bobs Meeting"
        And I follow "Close" within ".meeting_agenda"
        And I confirm the JS confirm dialog

       Then I should be on the show page of the meeting called "Bobs Meeting"
        And the minutes should contain the following text:
            | blubber |

       When I follow "Agenda"
       Then I should not see "Close" within ".meeting_agenda"
        And I should see "Open" within ".meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with permission to close and open the meeting agenda
      Given the role "user" may have the following rights:
            | view_meetings         |
            | close_meeting_agendas |
            # This won't work because the needed "click on open" has a confirm() which cucumber doesn't seem to handle
      # And the meeting "Bobs Meeting" has 1 agenda with:
      #     | locked | true |
       When I am already logged in as "alice"
        And I go to the show page of the meeting called "Bobs Meeting"
        And I follow "Agenda"
      # And I click on "Open"
       Then I should not see "Open" within ".meeting_agenda"
        And I should see "Close" within ".meeting_agenda"

  @javascript
  Scenario: Navigate to a meeting page with a closed meeting agenda and permission to edit meeting agendas
      Given the role "user" may have the following rights:
            | view_meetings          |
            | create_meeting_agendas |
        And the meeting "Bobs Meeting" has 1 agenda with:
            | locked | true |
       When I am already logged in as "alice"
        And I go to the show page of the meeting called "Bobs Meeting"
        And I follow "Agenda"
       Then I should not see "Edit" within ".meeting_agenda"
