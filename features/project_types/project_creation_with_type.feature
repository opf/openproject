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

Feature: Project creation with support for project type
  As a ChiliProject Admin
  I want to set a project type when creating a project
  So that the default planning element types are enabled automatically

  Background:
    Given there are the following types:
          | Name           | Is default |
          | Phase          | true       |
          | Milestone      | false      |
          | Something else | false      |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

  Scenario: The admin may create a project with a project type
    Given I am already admin
     When I go to the admin page
      And I follow "Projects"
      And I follow "New project"
     Then I fill in "Fancy Pants" for "Name"
      And I fill in "fancy-pants" for "Identifier"
      And I check "Timelines"
      And I select "Standard Project" from "Project type"
      And I press "Save"

     Then I should see a notice flash stating "Successful creation."

     When the following types are enabled for projects of type "Standard Project"
          | Phase     |
          | Milestone |
      And I go to the settings page of the project called "Fancy Pants"

     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
