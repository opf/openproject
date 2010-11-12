Feature: Cost Reporting Calculations

  Scenario: Different Rates are calculated differently
    Given there is a standard cost control project named "Cost Project"
    And there is 1 hourly rate with the following:
      | rate       | 1           |
      | user       | manager     |
      | valid from | 1 year ago  |
    And there is 1 hourly rate with the following:
      | rate       | 5           |
      | user       | manager     |
      | valid from | 2 years ago |
    And there is 1 default hourly rate with the following:
      | rate       | 10          |
      | user       | manager     |
      | valid from | 3 years ago |
    And the project "Cost Project" has 1 time entry with the following:
      | hours    | 10            |
      | user     | manager       |
      | spent on | 6 months ago |
    And the project "Cost Project" has 1 time entry with the following:
      | hours    | 10            |
      | user     | manager       |
      | spent on | 18 months ago |
    And the project "Cost Project" has 1 time entry with the following:
      | hours    | 10            |
      | user     | manager       |
      | spent on | 30 months ago |
    And I am admin
    And I am on the Cost Reports page for the project called "Cost Project" without filters or groups
    Then I should see "10.00" # 1 EUR x 10 (hours)
    And I should see "50.00"  # 5 EUR x 10 (hours)
    And I should see "100.00" # 10 EUR x 10 (hours)
    And I should see "160.00"
