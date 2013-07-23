Feature: Administring the enumerations

  Scenario: Creating an enumeration
    Given I am admin

    When I go to the enumerations page
    And I create a new enumeration with the following:
      | type | activity |
      | name | New enumeration   |

    Then I should be on the enumerations page
    And I should see the enumeration:
      | type | activity          |
      | name | New enumeration   |
