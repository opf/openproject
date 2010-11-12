Feature: Permissions
######################
# Dimensions to test:
#
# see_cost_entries: none, own, all
# see_time_entries: none, own, all
# see_rates: none, own, all

  Scenario: Anonymous can not access the project specific cost reports page
    Given there is a standard permission test project named "Permission_Test"
    And I am not logged in
    And I am on the Cost Reports page for the project called "Permission_Test" without filters or groups
    Then I should see "Login:"
    And I should see "Password:"

  Scenario: Anonymous can not access the overall cost reports page as there are no other public projects
    Given there is a standard permission test project named "Permission_Test"
    And I am not logged in
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Login:"
    And I should see "Password:"

  Scenario: Admin sees everything
    Given there is a standard permission test project named "Permission_Test"
    And I am admin
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who has all rights sees everything
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_time_entries    |
      | view_own_cost_entries    |
      | view_cost_entries        |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who has no rights, sees nothing
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | none                     |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "403" # permission denied

  Scenario: User who may only see own cost entries, only sees his own cost entries without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may only see cost entries, sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may only see his own time entries, only sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_time_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may only see time entries, only sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may only see own time and cost entries, only sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_time_entries    |
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may only see own time entries, but all cost entries, sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_time_entries    |
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may only see own cost entries, but all time entries, sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_cost_entries    |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who my see all time and cost entries, sees them without costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_cost_entries        |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may see own costs, but no entries sees nothing
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "403" # access denied

  Scenario: User who may see own costs and own cost entries, sees them with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"       # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see own costs and all cost entries, sees all cost entries, but own costs only
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should not see "11.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may see own costs and own time entries, sees his entries with own costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_own_time_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: A user who may see own costs, own time entries and own cost entries, sees then with costs (as they are his costs)
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_own_time_entries    |
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see own costs, own time entries and all cost entries, only sees those entries and only own entries with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_own_time_entries    |
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may see own costs and time entries, only sees own time entries with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who can see own costs, all time entries and only his own cost entries, see only the requested entries where costs are only visible on own entries
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_own_cost_entries    |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see own costs and all entries, only sees his own entries attached with costs
  # ATTENTION: there is no right to see own CostEntry costs - so no costs for cost entries are visible after all
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_cost_entries        |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who can see all costs but no entries sees nothing after all
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "403" #access denied

  Scenario: User wh can see all costs and his own cost entries, only sees own cost entries with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "1.00 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see all costs and all cost entries, sees all cost entries with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "11.00 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should not see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may see all costs and own time entries, sees them with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_time_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see all costs, own time- and cost- entries, sees his own entires with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_time_entries    |
      | view_own_cost_entries    |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "1.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see all costs, own time entries and all cost entries, only sees them with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_time_entries    |
      | view_cost_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "11.01 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should not see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should see "1.0 ten"   # other

  Scenario: User who may see all costs and all time entries, sees them with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "0.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should not see "1.0 one"   # own
    And I should not see "1.0 ten"   # other

  Scenario: User who may see all costs, all time entries and his own cost entries, sees them with costs
    Given there is a standard permission test project named "Permission_Test"
    And the role "Testuser" may have the following rights:
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_cost_entries    |
      | view_time_entries        |
    And I am logged in as "testuser"
    And I am on the overall Cost Reports page without filters or groups
    Then I should see "Cost Report" within "#content"
    And I should not see "No data to display"
    # Costs
    And I should see "1.11 EUR" within ".result" # costs (0.01 [own, time] + 0.10 [other, time] + 1.00 [own, cost] + 11.00 [other, cost])
    And I should not see "-" within ".result"
    # TimeEntries
    And I should see "1.00 hour" # own
    And I should see "2.00 hour" # other
    # CostEntries
    And I should see "1.0 one"   # own
    And I should not see "1.0 ten"   # other
