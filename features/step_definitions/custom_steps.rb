#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

Given /^there is a standard permission test project named "([^\"]*)"$/ do |name|
  steps %Q{
    Given there is 1 project with the following:
      | Name | #{name}           |
    And the project "#{name}" has the following types:
      | name | position |
      | Bug  |     1    |
    And the project "#{name}" has 1 issue with:
      | subject | #{name}work_package   |
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
    And the issue "#{name}work_package" has 1 time entry with the following:
      | hours        | 1         |
      | user         | testuser  |
    And the issue "#{name}work_package" has 1 time entry with the following:
      | hours        | 2         |
      | user         | otheruser |
    And the work package "#{name}work_package" has 1 cost entry with the following:
      | units        | 1         |
      | user         | testuser  |
      | cost type    | one       |
    And the work package "#{name}work_package" has 1 cost entry with the following:
      | units        | 1         |
      | user         | otheruser |
      | cost type    | ten       |
  }
end

Given /^I set the filter "([^\"]*)" to "([^\"]*)" with the operator "([^\"]*)"$/ do |filter, value, operator|
  begin
    find_by_id("add_filter_select").find("[value='#{filter}']").select_option
    find("[name='operators[#{filter}]']").find("[value='#{operator}']").select_option
    find("[name='values[#{filter}][]']").find("[value='#{value}']").select_option
  rescue Capybara::ElementNotFound
    # we support both using all-values and all-texts parameters
    step %{I select "#{filter}" from "add_filter_select"}

    filter_id = find_by_id("add_filter_select").value
    step %{I select "#{operator}" from "operators[#{filter_id}]"}
    step %{I select "#{value}" from "#{filter_id}_arg_1_val"}
  end
end

Given /^I set the filter "([^\"]*)" to the user with the login "([^\"]*)" with the operator "([^\"]*)"$/ do |filter, login, operator|
  user_id = User.find_by_login(login).id
  step %{I set the filter "#{filter}" to "#{user_id}" with the operator "#{operator}"}
end

When /the user with the login "([^\"]*)" should be selected for "([^\"]*)"/ do |login, select_id|
  user_id = User.find_by_login(login).id
  step %{"#{user_id}" should be selected for "#{select_id}"}
end

When /^I send the query$/ do
  find("[id='query-icon-apply-button']").click
end

Then /^filter "([^\"]*)" should (not )?be visible$/ do |filter, negative|
  bool = negative ? false : true
  page.evaluate_script("$('tr_#{filter}').visible()") =~ /^#{bool}$/
end

Then /^(?:|I )should not see "([^\"]*)" in (columns|rows)$/ do |text, axis|
  page.all("fieldset#group_by_#{axis} span").each do |element|
    element.should_not have_content(text)
  end
end

Then /^(?:|I )should see "([^\"]*)" in (columns|rows)$/ do |text, axis|
  page.should have_xpath(".//fieldset[@id='group_by_#{axis}']/span[contains(label,'#{text}')]")
end

Given /^I group (rows|columns) by "([^\"]*)"/ do |target, group|
  step %{I select "#{group}" from "add_group_by_#{target}" within "#group_by_#{target}"}
end

Given /^I remove "([^\"]*)" from (rows|columns)/ do |group, source|
  element_name = find_by_id("group_by_#{source}").find("label", text: "#{group}")[:for]
  find_by_id("#{element_name}_remove").click
end

Given /^I (delete|remove) the (cost|time) entry "([^\"]*)"$/ do |method, type, name|
  begin
    find(:xpath, "//tr[td=#{name}]/td/a[@title='Delete']").click
  rescue Capybara::ElementNotFound
    find(:xpath, "//tr[td[@raw-data='#{name}']]/td/a[@title='Delete']").click
  end
  step %{I accept the alert dialog}
end

Given /^I edit the report name in place$/ do
  find(:css, "#query_saved_name").click
end

Then /^I see spent time$/ do
  page.should have_content(/spent time/i)
end
