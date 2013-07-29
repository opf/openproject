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
    Given there are the following planning element types:
          | Name           |
          | Phase          |
          | Milestone      |
          | Something else |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And the following types are default for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And the following types are default for projects of type "Extraordinary Project"
          | Something else |


  Scenario: The admin may create a project with a project type
    Given I am logged in as "admin"
     When I go to the admin page
      And I follow "Projects"
      And I follow "New project"
     Then I fill in "Fancy Pants" for "Name"
      And I fill in "fancy-pants" for "Identifier"
      And I check "Timelines"
      And I select "Standard Project" from "Project type"
      And I press "Save"

     Then I should see a notice flash stating "Successful creation."

     When I go to the settings/timelines page of the project called "Fancy Pants"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
      And the "Phase" row should be marked as default
      And the "Milestone" row should be marked as default

  Scenario: The project admin may change the project type, planning element types remain unchanged
    Given there is 1 user with:
          | login | padme |

      And there is a role "project admin"
      And the role "project admin" may have the following rights:
          | edit_project                           |
          | manage_project_configuration |

      And there is a project named "Fancy Pants" of type "Standard Project"
      And I am working in project "Fancy Pants"

      And the project uses the following modules:
          | timelines |

      And the user "padme" is a "project admin"

      And I am logged in as "padme"

     When I go to the settings page of the project called "Fancy Pants"
      And I select "Extraordinary Project" from "Project type"
      And I press "Save" within "#tab-content-info"

     Then I should see a notice flash stating "Successful update."

     When I go to the settings/timelines page of the project called "Fancy Pants"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
      And the "Something else" checkbox should not be checked

      And the "Phase" row should not be marked as default
      And the "Milestone" row should not be marked as default
      And the "Something else" row should be marked as default
