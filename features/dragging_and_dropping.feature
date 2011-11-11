Feature: Custom Overview Page
  Background:
    Given there is a standard cost control project named "Cost Project"
    And I am admin
    And I am on the overview page for the project "Cost Project"$/

  Scenario: Dragging, adding and deleting elements
    Given I start editing the overview page
    Then I should be able to change things and see my changes when I finish

  Scenario: Adding, editing and deleting Teaser elements
    Given I start editing the overview page
    Then I should be able to add a teaser element with custom text
    Given I start editing the overview page again
    Then I should be able to delete a teaser element

