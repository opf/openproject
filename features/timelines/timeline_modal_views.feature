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

Feature: Timeline View Tests
	As a Project Member
	I want edit planning elements via a modal window

  Background:
    Given there are the following types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | view_timelines     |
          | edit_timelines     |
          | view_work_packages |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the following types are enabled for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am already logged in as "manager"

      And there are the following work packages:
          | Start date | Due date   | description         | responsible | Subject  |
          | 2012-01-01 | 2012-01-31 | #2 http://google.de | manager     | January  |
          | 2012-02-01 | 2012-02-24 | Avocado Rincon      | manager     | February |
          | 2012-03-01 | 2012-03-30 | Hass                | manager     | March    |
          | 2012-04-01 | 2012-04-30 | Avocado Choquette   | manager     | April    |
          | 2012-04-01 | 2012-04-30 | Relish              | manager     | Test2    |

  @javascript
  Scenario: planning element click should show modal window
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
     Then I should see a modal window
      And I should see "#1: January" in the modal
      And I should see "http://google.de" in the modal
      And I should see "01/01/2012" in the modal
      And I should see "01/31/2012" in the modal
      And I should see "New timeline report"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"
     When I ctrl-click on "#2" in the modal
     Then I should see "February" in the new window
     Then I should see "Avocado Rincon" in the new window
