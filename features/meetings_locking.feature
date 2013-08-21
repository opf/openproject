#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Locking meetings

  Background:
        Given there is 1 project with the following:
              | identifier | dingens |
              | name       | dingens |
          And the project "dingens" uses the following modules:
              | meetings |
          And there is 1 user with:
              | login | bob |
          And there is a role "user"
          And the user "bob" is a "user" in the project "dingens"
          And there is 1 meeting in project "dingens" created by "bob" with:
              | title | Bobs Meeting |
          And the meeting "Bobs Meeting" has 1 agenda with:
              | text  | awesome! |

  @javascript
  Scenario: Save a meeting after it has changed while editing
      Given the role "user" may have the following rights:
            | view_meetings |
            | create_meetings |
            | create_meeting_agendas |
            | edit_meetings |
       When I am already logged in as "bob"
        And I go to the Meetings page for the project called "dingens"
        And I click on "Bobs Meeting"
        And I follow "Edit" within ".meeting_agenda"
            # Change the text of the agenda to create an editing conflict
        And the meeting "Bobs Meeting" has 1 agenda with:
            | text | and now for something completely different |
        And I fill in "Blabla oder?" for "meeting_agenda_text"
        And I click on "Save"
       Then I should see "Information has been updated by at least one other user in the meantime."
            # Prüfen, ob die Editbox noch sichtbar ist
       #And I should see "Text formatting" within "#tab-content-agenda"
