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

Given /^I set the filter "([^\"]*)" to "([^\"]*)" with the operator "([^\"]*)"$/ do |filter, value, operator|
  find :xpath, "//body"
  find(:xpath, "//add_filter_select/option[value='#{filter}']").select_option
end

When /^I send the query$/ do
  find(:xpath, '//p[@class="buttons"]/a[@class="button apply"]').click
end

Then /^filter "([^\"]*)" should (not )?be visible$/ do |filter, negative|
  bool = negative ? false : true
  page.evaluate_script("$('tr_#{filter}').visible()") =~ /^#{bool}$/
end

Then /^(?:|I )should( not)? see "([^\"]*)" in columns$/ do |negation, text|
  columns = "div[@id='group_by_columns']"
  begin
    When %{I should#{negation} see "#{text}" within "#{columns}"}
  rescue Selenium::WebDriver::Error::ObsoleteElementError
    # Slenium might not find the right DOM element due to a rais condition - try again
    # see: http://groups.google.com/group/ruby-capybara/browse_thread/thread/76c194b92c58ecef
    When %{I should#{negation} see "#{text}" within "#{columns}"}
  end
end

Then /^(?:|I )should( not)? see "([^\"]*)" in rows$/ do |negation, text|
  rows = "div[@id='group_by_rows']"
  begin
    When %{I should#{negation} see "#{text}" within "#{rows}"}
  rescue Selenium::WebDriver::Error::ObsoleteElementError
    # Slenium might not find the right DOM element due to a rais condition - try again
    # see: http://groups.google.com/group/ruby-capybara/browse_thread/thread/76c194b92c58ecef
    When %{I should#{negation} see "#{text}" within "#{rows}"}
  end
end

Given /^I group (rows|columns) by "([^\"]*)"/ do |target, group|
  When %{I select "#{group}" from "add_group_by_#{target}"}
end

Given /^I remove "([^\"]*)" from (rows|columns)/ do |group, source|
  When %{I select "#{group}" from "group_by_#{source}"}
  find("//span[data-group-by='#{group}']/.group_by_remove").click
end

