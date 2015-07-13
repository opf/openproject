#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

Given /^there is 1 cost type with the following:$/ do |table|
  ct = FactoryGirl.build(:cost_type)
  send_table_to_object(ct, table, {
    cost_rate: Proc.new do |o,v|
      FactoryGirl.create(:cost_rate, rate: v,
                                     cost_type: o)
    end,
    name: Proc.new do |o,v|
      o.name = v
      o.unit = v
      o.unit_plural = "#{v}s"
      o.save!
    end})
end

When(/^I delete the cost type "(.*?)"$/) do |name|
  step %{I go to the index page of cost types}

  ct = CostType.find_by_name name

  within ("#delete_cost_type_#{ct.id}") do
    find('a.submit_cost_type').click
  end

  if page.driver.is_a? Capybara::Selenium::Driver
    # confirm "really delete?"
    page.driver.browser.switch_to.alert.accept
  end
end

When(/^I click the delete link for the cost type "(.*?)"$/) do |name|
  ct = CostType.find_by_name name

  within ("#delete_cost_type_#{ct.id}") do
    find('a.submit_cost_type').click
  end
end

When /^I expect to click "([^"]*)" on a confirmation box saying "([^"]*)"$/ do |option, message|
  retval = (option == 'OK') ? 'true' : 'false'
  page.evaluate_script("window.confirm = function (msg) {
    document.cookie = msg
    return #{retval}
  }")
  @expected_message = message.gsub("\\n", "\n")
end

When /^the confirmation box should have been displayed$/ do
  assert page.evaluate_script('document.cookie').include?(@expected_message),
         "Expected confirm box with message: '#{@expected_message}'" +
             " got: '#{page.evaluate_script('document.cookie')}'"
end

Then(/^the cost type "(.*?)" should not be listed on the index page$/) do |name|

  if has_css?(".cost_types")
    within ".cost_types" do
      should_not have_link(name)
    end
  end
end

Then(/^the cost type "(.*?)" should be listed as deleted on the index page$/) do |name|
  check(I18n.t(:caption_show_locked))

  click_link(I18n.t(:button_apply))

  within ".deleted_cost_types" do
    should have_text(name)
  end
end
