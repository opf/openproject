Given /^there is a standard permission test project named "([^\"]*)"$/ do |name|
  steps %Q{
    Given there is 1 project with the following:
      | Name | #{name}           |
    And the project "#{name}" has 1 issue with:
      | subject | #{name}issue   |
      And there is a role "Testuser"
    And the role "Testuser" may have the following rights:
      | view_own_hourly_rate     |
      | view_hourly_rates        |
      | view_cost_rates          |
      | view_own_time_entries    |
      | view_own_cost_entries    |
      | view_cost_entries        |
      | view_time_entries        |
    And there is 1 User with:
      | Login        | testuser  |
      | Firstname    | Test      |
      | Lastname     | User      |
      | default rate | 0.01      |
    And the user "testuser" is a "Testuser" in the project "#{name}"
    And there is 1 User with:
      | Login        | otheruser |
      | Firstname    | Other     |
      | Lastname     | User      |
      | default rate | 0.05      |
    And the user "otheruser" is a "Testuser" in the project "#{name}"
    And there is 1 cost type with the following:
      | name         | one       |
      | cost rate    | 1.00      |
    And there is 1 cost type with the following:
      | name         | ten       |
      | cost rate    | 10.00     |
    And the issue "#{name}issue" has 1 time entry with the following:
      | hours        | 1         |
      | user         | testuser  |
    And the issue "#{name}issue" has 1 time entry with the following:
      | hours        | 2         |
      | user         | otheruser |
    And the issue "#{name}issue" has 1 cost entry with the following:
      | units        | 1         |
      | user         | testuser  |
      | cost type    | one       |
    And the issue "#{name}issue" has 1 cost entry with the following:
      | units        | 1         |
      | user         | otheruser |
      | cost type    | ten       |
  }
end

Given /^I set the filter "([^"]*)" to "([^"]*)" with the operator "([^"]*)"$/ do |filter, value, operator|
  locate :xpath, "//body"
  page.evaluate_script("restore_filter(\"#{filter}\", \"#{operator}\", \"#{value}\")")
end

Then /^filter "([^"]*)" should (not )?be visible$/ do |filter, negative|
  bool = negative ? false : true
  page.evaluate_script("$('tr_#{filter}').visible()") =~ /^#{bool}$/
end

Given /^I group (rows|columns) by "([^"]*)"/ do |target, group|
  destination = target == "rows" ? "moveLeft" : "moveUp"
  When %{I select "#{group}" from "group_by_container"}
  find(:xpath, "//input[@class='buttons group_by move #{destination}']").click
end

When /^I send the query$/ do
  find(:xpath, '//p[@class="buttons"]/a[@class="button apply"]').click
end

