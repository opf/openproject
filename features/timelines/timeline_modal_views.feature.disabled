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
	I want to view the timeline data
	change the timeline selection
	edit planning elements via a modal window

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
          | view_timelines                  |
          | edit_timelines                  |
          | view_planning_elements          |
          | move_planning_elements_to_trash |
          | delete_planning_elements        |
          | edit_planning_elements          |
          | delete_planning_elements        |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the following types are enabled for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And the project uses the following modules:
          | timelines |

      And the user "manager" is a "manager"

      And I am already logged in as "manager"

      And there are the following planning elements:
          | Start date | Due date   | description       | planning_element_status | responsible | Subject                                                                                                                       |
          | 2012-01-01 | 2012-01-31 | Avocado Hall      | closed                  | manager     | January                                                                                                                       |
          | 2012-02-01 | 2012-02-24 | Avocado Rincon    | closed                  | manager     | February                                                                                                                      |
          | 2012-03-01 | 2012-03-30 | Hass              | closed                  | manager     | March                                                                                                                         |
          | 2012-04-01 | 2012-04-30 | Avocado Choquette | closed                  | manager     | April                                                                                                                         |
          | 2012-04-01 | 2012-04-30 | Relish            | closed                  | manager     | Loremipsumdolorsitamet,consecteturadipisicingelit,seddoeiusmodtemporincididuntutlaboreetdoloremagnaaliqua.Utenimadminimveniam |

  @javascript
  Scenario: planning element click should show modal window
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
     Then I should see the planning element edit modal
      And I should see "January (*1)"
      And I should see "Avocado Hall"
      And I should see "01/01/2012 - 01/31/2012"
      And I should see "New timeline report"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

  @javascript
  Scenario: edit should open edit
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
      And I click on the Edit Link
     Then I should see the planning element edit modal
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"
      And I should see "Save"
      And I should see "Cancel"

  @javascript
  Scenario: edit in modal
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
      And I click on the Edit Link
      And I set duedate to "2012-01-30"
      And I click on the Save Link

     Then I should be on the page of the timeline "Testline" of the project called "ecookbook"
      And I should see "01/01/2012 - 01/30/2012"

  @javascript
  Scenario: enter wrong date in modal
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I click on the Planning Element with name "January"
      And I click on the Edit Link
      And I set duedate to "2011-01-30"
      And I click on the Save Link

     Then I should be on the page of the timeline "Testline" of the project called "ecookbook"
      And I should see "Due date must be greater than start date"

  @javascript
  Scenario: trash element
     When there is a timeline "Testline" for project "ecookbook"
      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I wait for timeline to load table
      And I trash the planning element with name "January"

     Then I should be on the page of the timeline "Testline" of the project called "ecookbook"
      And I should not see "January"

  @javascript
  Scenario: trash vertical should be removed
     When there is a timeline "Testline" for project "ecookbook"
      And I make the planning element "January" vertical for the timeline "Testline" of the project called "ecookbook"

      And I go to the page of the timeline "Testline" of the project called "ecookbook"
      And I trash the planning element with name "January"

     Then I should not see the planning element "January"
