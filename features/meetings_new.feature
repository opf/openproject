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

Feature: Create new meetings

  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login    | alice |
              | language | en    |
          And there is a role "user"
          And the user "alice" is a "user" in the project "dingens"

  Scenario: Navigate to the meeting index page with no permission to create new meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
       Then I should not see "New Meeting"

  Scenario: Navigate to the meeting index page with permission to create new meetings
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
       Then I should see "New Meeting"

  Scenario: Create a new meeting with no title
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
        And I click on "Create"
       Then I should see "Title can't be blank"

  Scenario Outline: Create a new meeting with a title and a date, time, and duration with no and different time zones set
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I am already logged in as "alice"
       And the user "alice" has the following preferences
              | time_zone | <t_zone> |
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
        And I fill in the following:
            | meeting_title         | FSR Sitzung 123 |
            | meeting_start_date    | 2013-03-28      |
            | meeting_duration      | 1.5             |
        And I select "13" from "meeting_start_time_4i"
        And I select "30" from "meeting_start_time_5i"
        And I click on "Create"
       Then I should see "Successful creation."
        And I should see "FSR Sitzung 123"
        And I should see "03/28/2013 01:30 pm - 03:00 pm"

  Examples:
    | t_zone |
    | nil    |
    | UTC    |
    | CET    |
    | CEST   |

  @javascript
  Scenario: The start-time should be selectable in 5-minute increments
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
       Then I should see "New Meeting"
        And I should not see "01" within "#meeting_start_time_5i"
        And I should not see "14" within "#meeting_start_time_5i"
        And I should see "00" within "#meeting_start_time_5i"
        And I should see "05" within "#meeting_start_time_5i"

  Scenario: Visit the new meeting page to make sure the author is selected as invited
      Given the role "user" may have the following rights:
            | view_meetings   |
            | create_meetings |
       When I am already logged in as "alice"
        And I go to the Meetings page for the project called "dingens"
        And I click on "New Meeting"
       Then the "meeting[participants_attributes][][invited]" checkbox should be checked

  Scenario: Create a meeting in a project without members shouldn't error out
    Given there is 1 project with the following:
      | identifier | foreverempty |
      | name       | foreverempty |
    And the project "foreverempty" uses the following modules:
      | meetings |
    When I am already admin
    And I go to the Meetings page for the project called "foreverempty"
    And I click on "New Meeting"
    And I fill in the following:
      | meeting_title | Emtpy Meetings |
    And I press "Create"
    Then I should see "Successful creation."
