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

  Scenario: The project manager gets 'No data to display' when there are no planning elements defined
     When I go to the page of the timeline of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "General Settings"

  Scenario: Creating a timeline
     When there is a timeline "Testline" for project "ecookbook"
     When I go to the page of the timeline "Testline" of the project called "ecookbook"
     Then I should see "New timeline report"
      And I should see "Testline"
      And I should be on the page of the timeline "Testline" of the project called "ecookbook"

