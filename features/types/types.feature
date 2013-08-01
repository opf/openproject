#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Feature: Types Settings
  As a Project Admin
  I want to configure which types are available in my project
  So that I can adjust the global settings inherited by the type
  So that my team and I can work effectively

  Background:
    Given there are the following types:
          | Name           | is_default |
          | Phase          | true       |
          | Milestone      | true       |
          | Something else | false      |

      And there is a project named "ecookbook"
      And I am working in project "ecookbook"

      And there is 1 user with:
          | login | padme |
      And there is a role "project admin"
      And the role "project admin" may have the following rights:
          | edit_project                 |
          | manage_project_configuration |
      And the user "padme" is a "project admin"

      And I am already logged in as "padme"

  Scenario: The project admin may see the currently enabled types
     When I go to the settings page of the project called "ecookbook"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
      And the "Something else" checkbox should not be checked

  Scenario: The project admin may set the currently enabled types
     When I go to the settings page of the project called "ecookbook"
      And I check "Something else"
      And I uncheck "Milestone"
      And I press "Save"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should not be checked
      And the "Something else" checkbox should be checked
