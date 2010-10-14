Feature: Permissions
#XXX: Test permissions on table and simple table (currently testet in _cost_entry_table partial only)
#XXX: Test access permissions for /cost_reports AND /project/../cost_reports - sometimes there is access denied where is should not and vice versa

  Scenario: Coming to the cost report for the first time, I should see my entries
    Given there is a standard cost control project named "Standard Project"