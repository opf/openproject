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

Feature: Show existing meetings

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
          And the role "user" may have the following rights:
              | view_meetings |
          And the user "alice" is a "user" in the project "dingens"

  Scenario: Navigate to the meeting index page with no meetings
       When I am already logged in as "alice"
        And I go to the page for the project "dingens"
        And I click on "Meetings"
       Then I should see "Meetings" within "#content"
        And I should see "There is currently nothing to display." within "#content"

  Scenario: Navigate to the meeting index page with 2 meetings
      Given there is 1 meeting in project "dingens" created by "alice" with:
            | title      | Meeting 1           |
            | location   | Room 1              |
            | duration   | 1:30                |
            | start_time | 2011-02-11 12:30:00 |
        And there is 1 meeting in project "dingens" created by "alice" with:
            | title      | Meeting 2           |
            | location   | Room 2              |
            | duration   | 2:30                |
            | start_time | 2011-02-10 11:00:00 |
       When I am already logged in as "alice"
        And I go to the page for the project "dingens"
        And I click on "Meetings"
       Then I should see "Meetings" within "#content"
        But I should not see "There is currently nothing to display." within "#content"
        And I should see 4 meetings

  Scenario: Lots of Meetings are split into pages
      Given we paginate after 3 items
      Given there is 3 meetings in project "dingens" that start 0 days from now with:
            | title | Meeting Today     |
      Given there is 2 meetings in project "dingens" that start -1 days from now with:
            | title | Meeting Last Week |
       When I am already logged in as "alice"
        And I go to the page for the project "dingens"
        And I click on "Meetings"
         # see above: means 3 meetings
       Then I should see 6 meetings
        And I should see "Meeting Today"
        But I should not see "Meeting Last Week"
       When I click on "2"
         # means 2 meetings
       Then I should see 4 meetings
        And I should not see "Meeting Today"
        But I should see "Meeting Last Week"

  Scenario: Jumps to page of current date when no page given
      Given we paginate after 3 items
      Given there is 5 meetings in project "dingens" that start +7 days from now with:
            | title | Meeting Next Week |
      Given there is 5 meetings in project "dingens" that start 1 days from now with:
            | title | Meeting Tomorrow  |
      Given there is 5 meetings in project "dingens" that start 0 days from now with:
            | title | Meeting Today     |
      Given there is 5 meetings in project "dingens" that start -7 days from now with:
            | title | Meeting Last Week |
       When I am already logged in as "alice"
        And I go to the page for the project "dingens"
        And I click on "Meetings"
       Then I should see "Meeting Today"
        And I should see "Meeting Tomorrow"
        But I should not see "Meeting Last Week"
        And I should not see "Meeting Next Week"
