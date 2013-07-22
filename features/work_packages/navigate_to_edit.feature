Feature: Navigating to the work package edit page
  Scenario: Directly opening the page
    Given there is 1 user with:
        | login | manager |

    And there is a role "manager"
    And the role "manager" may have the following rights:
      | edit_work_packages |

    And there is 1 project with the following:
      | identifier | ecookbook |
      | name       | ecookbook |
    And I am working in project "ecookbook"

    And the user "manager" is a "manager"

    And there are the following planning elements in project "ecookbook":
      | subject | start_date | due_date   |
      | pe1     | 2013-01-01 | 2013-12-31 |

    And I am already logged in as "manager"

    When I go to the edit page of the work package called "pe1"
    Then I should be on the edit page of the work package called "pe1"
