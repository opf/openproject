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

Feature: Enabled Planning Element Types Settings
  As a Project Admin
  I want to configure which planning element types are available in my project
  So that I can adjust the global settings inherited by the project type
  So that my team and I can work effectively

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

      And there is 1 user with:
          | login | padme |

      And there is a role "project admin"
      And the role "project admin" may have the following rights:
          | edit_project                           |
          | manage_project_configuration |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |

      And the user "padme" is a "project admin"

      And I am already logged in as "padme"

  Scenario: The project admin may see the currently enabled planning element types
     When I go to the settings/timelines page of the project called "ecookbook"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should be checked
      And the "Something else" checkbox should not be checked

  Scenario: The project admin may see the default planning element types defined by the project type
     When I go to the settings/timelines page of the project called "ecookbook"
     Then the "Phase" row should be marked as default
      And the "Milestone" row should be marked as default
      And the "Something else" row should not be marked as default

  Scenario: The project admin may see no default planning element types f the project has no project type
    Given the project has no project type
     When I go to the settings/timelines page of the project called "ecookbook"
     Then the "Phase" row should not be marked as default
      And the "Milestone" row should not be marked as default
      And the "Something else" row should not be marked as default

  Scenario: The project admin may set the currently enabled planning element types
     When I go to the settings/timelines page of the project called "ecookbook"
      And I check "Something else"
      And I uncheck "Milestone"
      And I press "Save" within "#tab-content-timelines"
     Then the "Phase" checkbox should be checked
      And the "Milestone" checkbox should not be checked
      And the "Something else" checkbox should be checked
