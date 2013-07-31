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

Feature: Planning elements textile quickinfo links
  Background:
    Given there are the following planning element types:
          | Name      | Is Milestone | In aggregation |
          | Phase     | false        | true           |
          | Milestone | true         | true           |

      And there are the following project types:
          | Name                  |
          | Standard Project      |
          | Extraordinary Project |

      And the following planning element types are default for projects of type "Standard Project"
          | Phase     |
          | Milestone |

      And there is 1 user with:
          | login | manager |

      And there is a role "manager"
      And the role "manager" may have the following rights:
          | manage_wiki     |
          | view_wiki_pages |
          | edit_wiki_pages |

      And there is a project named "ecookbook" of type "Standard Project"
      And I am working in project "ecookbook"

      And the project uses the following modules:
          | timelines |
          | wiki |

      And the user "manager" is a "manager"
      Given there are the following planning element statuses:
              | Name     |
              | closed   |
      Given there are the following planning elements:
              | Subject | Start date | Due date   | description                | planning_element_status | responsible |
              | January | 2012-01-01 | 2012-01-31 | Avocado Sali Grande Grande | closed                  | manager     |

  Scenario: Adding a planning element link
    Given I am already logged in as "admin"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in the planning element ID of "January" with 1 star for "content_text"
    And I press "Save"
    Then I should see a planning element link for "January" within "div.wiki"
    When I follow the planning element link with 1 star for "January"
    Then I should be on the page of the planning element "January" of the project called "ecookbook"

  Scenario: Adding a planning element quickinfo link
    Given I am already logged in as "admin"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in the planning element ID of "January" with 2 star for "content_text"
    And I press "Save"
    Then I should see a planning element quickinfo link for "January" within "div.wiki"
    When I follow the planning element link with 2 star for "January"
    Then I should be on the page of the planning element "January" of the project called "ecookbook"

  Scenario: Adding a planning element quickinfo link with description
    Given I am already logged in as "admin"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in the planning element ID of "January" with 3 star for "content_text"
    And I press "Save"
    Then I should see a planning element quickinfo link with description for "January" within "div.wiki"
    When I follow the planning element link with 3 star for "January"
    Then I should be on the page of the planning element "January" of the project called "ecookbook"

  Scenario: Adding a planning element quickinfo link without the right to see the planning element
    Given I am already logged in as "manager"
    When I go to the wiki page "testitest" for the project called "ecookbook"
    And I fill in the planning element ID of "January" with 3 star for "content_text"
    And I press "Save"
    Then I should not see a planning element quickinfo link with description for "January" within "div.wiki"
