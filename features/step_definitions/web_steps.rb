#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'paths'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'selectors'))

module WithinHelpers
  def press_key_on_element(key, element)
    page.find(element).native.send_keys(Selenium::WebDriver::Keys[key.to_sym])
  end

  def right_click(elements)
    builder = page.driver.browser.action

    Array(elements).each do |e|
      builder.context_click(e.native)
    end

    builder.perform
  end

  def ctrl_click(elements)
    builder = page.driver.browser.action

    # Hold control key down
    builder.key_down(:control)

    # Note that you can retrieve the elements using capybara's
    #  standard methods. When passing them to the builder
    #  make sure to do .native
    Array(elements).each do |e|
      builder.click(e.native)
    end

    # Release control key
    builder.key_up(:control)

    # Do the action setup
    builder.perform
  end

  def with_scope(locator, options = {})
    locator ? within(*selector_for(locator), options) { yield } : yield
  end
end
World(WithinHelpers)

# Single-line step scoper
When /^(.*) within "(.*[^:"])"$/ do |step_name, parent|
  with_scope(parent) { step step_name }
end

When /^(.*) \[i18n\]$/ do |actual_step|
  step translate(actual_step)
end

When(/^I ctrl\-click on "([^\"]+)"$/) do |text|
  # Click all elements that you want, in this case we click all as
  elements = page.all('a', text: text)
  ctrl_click(elements)
end

# Single-line step scoper
When /^(.*) within_hidden (.*[^:])$/ do |step_name, parent|
  with_scope(parent, visible: false) { step step_name }
end

# Multi-line step scoper
When /^(.*) within (.*[^:]):$/ do |step_name, parent, table_or_string|
  with_scope(parent) { step "#{step_name}:", table_or_string }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^"]*)"$/ do |button|
  click_button(button)
end

When /^(?:|I )follow "([^"]*)"$/ do |link|
  click_link(link)
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  fill_in(field, with: value)
end

When /^(?:|I )fill in "([^"]*)" for "([^"]*)"$/ do |value, field|
  fill_in(field, with: value)
end

# Use this to fill in an entire form with data from a table. Example:
#
#   When I fill in the following:
#     | Account Number | 5002       |
#     | Expiry date    | 2009-11-01 |
#     | Note           | Nice guy   |
#     | Wants Email?   |            |
#
# TODO: Add support for checkbox and option
# based on naming conventions.
#
When /^(?:|I )fill in the following:$/ do |fields|
  fields.rows_hash.each do |name, value|
    field = find_field(name)

    if field.tag_name == 'select'
      step(%{I select "#{value}" from "#{name}"})
    else
      step(%{I fill in "#{name}" with "#{value}"})
    end
  end
end

When (/^I do some ajax$/) do
  click_link('Apply')
end

When /^(?:|I )select "([^"]*)" from "([^"]*)"$/ do |value, field|
  select(value, from: field)
end

When /^(?:|I )check "([^"]*)"$/ do |field|
  check(field)
end

When /^(?:|I )uncheck "([^"]*)"$/ do |field|
  uncheck(field)
end

When /^(?:|I )choose "([^"]*)"$/ do |field|
  choose(field)
end

When /^(?:|I )attach the file "([^"]*)" to "([^"]*)"$/ do |path, field|
  attach_file(field, File.expand_path(path))
end

Then /^(?:|I )should see "([^"]*)"$/ do |text|
  regexp = Regexp.new(Regexp.escape(text), Regexp::IGNORECASE)
  page.should have_content(regexp)
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)

  should have_content(regexp)
end

Then(/^(?:|I )should not see "([^"]*)" in the same table row as "([^"]*)"$/) do |text1, text2|
  within('table.generic-table tbody') do
    page.all(:xpath, "//tr/td[contains(.,'#{text2}')]/following-sibling::td").each do |td|
      expect(td).to have_no_content(text1)
    end
  end
end

Then /^(?:|I )should not see "([^"]*)"$/ do |text|
  regexp = Regexp.new(Regexp.escape(text), Regexp::IGNORECASE)
  page.should have_no_content(regexp)
end

Then /^(?:|I )should not see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)

  should have_no_content(regexp)
end

Then /^the "([^"]*)" field(?: within (.*))? should contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field.value.should =~ /#{value}/
  end
end

Then /^the "([^"]*)" field(?: within (.*))? should not contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field.value.should_not =~ /#{value}/
  end
end

Then /^the "([^"]*)" field should have the error "([^"]*)"$/ do |field, error_message|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')

  form_for_input = element.find(:xpath, 'ancestor::form[1]')
  using_formtastic = form_for_input[:class].include?('formtastic')
  error_class = using_formtastic ? 'error' : 'field_with_errors'

  classes.should include(error_class)

  if using_formtastic
    error_paragraph = element.find(:xpath, '../*[@class="inline-errors"][1]')
    error_paragraph.should have_content(error_message)
  else
    page.should have_content("#{field.titlecase} #{error_message}")
  end
end

Then /^the "([^"]*)" field should have no error$/ do |field|
  element = find_field(field)
  classes = element.find(:xpath, '..')[:class].split(' ')
  classes.should_not include('field_with_errors')
  classes.should_not include('error')
end

Then /^the (hidden )?"([^"]*)" checkbox should be checked$/ do |hidden, label|
  field_checked = find_field(label, visible: hidden.nil?)['checked']
  field_checked.should be_truthy
end

Then /^the (hidden )?"([^"]*)" checkbox should not be checked$/ do |hidden, label|
  field_checked = find_field(label, visible: hidden.nil?)['checked']
  field_checked.should be_falsey
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  CGI.unescape(current_path).should == CGI.unescape(path_to(page_name))
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  query = URI.parse(current_url).query
  actual_params = query ? CGI.parse(query) : {}
  expected_params = {}
  expected_pairs.rows_hash.each_pair { |k, v| expected_params[k] = v.split(',') }

  actual_params.should == expected_params
end

Then /^show me the page$/ do
  # save_and_open_page
  sleep 2 # sleep to ensure page has been fully loaded
  save_and_open_screenshot
end

# newly generated until here

When /^I wait(?: (\d+) seconds)? for(?: the)? [Aa][Jj][Aa][Xx](?: requests?(?: to finish)?)?$/ do |timeout|
  ajax_done = lambda do
    is_done = false
    while !is_done
      is_done = page.evaluate_script(%{
        (function (){
          return !(window.jQuery && document.ajaxActive);
        }())
      }.gsub("\n", ''))
    end
  end

  timeout = timeout.present? ?
              timeout.to_f :
              5.0

  wait_until(timeout, i_know_im_immoral: true) do
    ajax_done.call
  end
end

Then /^there should be a( disabled)? "(.+)" field( visible| invisible)?$/ do |disabled, fieldname, visible|
  # Checking for a disabled field will only work for field with labels where the label
  # has a correctly filled "for" attribute
  visibility = visible && !visible.include?('invisible')

  if disabled
    # disabled fields can not be found via find_field
    field_id = find('label', text: fieldname)['for']
    should have_css("##{field_id}", visible: visibility)
  else
    should have_field(fieldname, visible: visibility)
  end
end

Then /^there should not be a "(.+)" field$/ do |fieldname|
  should_not have_field(fieldname)
end

Then /^there should be a "(.+)" button$/ do |button_label|
  page.should have_xpath("//input[@value='#{button_label}']")
end

Then /^the "([^\"]*)" select(?: within "([^\"]*)")? should have the following options:$/ do |field, selector, option_table|
  options_expected = option_table.raw.flatten

  with_scope(selector) do
    field = find_field(field)
    options_actual = field.all('option').map(&:text)
    options_actual.should =~ options_expected
  end
end

Then /^there should be the disabled "(.+)" element$/ do |element|
  page.find(element)[:disabled].should == 'true'
end

Then /^the element "(.+)" should be invalid$/ do |element|
  expect(page).to have_selector("#{element}:invalid")
end

# This needs an active js driver to work properly
Given /^I (accept|dismiss) the alert dialog$/ do |method|
  if Capybara.current_driver.to_s.include?('selenium')
    page.driver.browser.switch_to.alert.send(method.to_s)
  end
end

Then(/^(.*) in the new window$/) do |step|
  new_window = windows.last
  page.within_window new_window do
    step(step)
  end
end

Then /^(.*) in the iframe "([^\"]+)"$/ do |step, iframe_name|
  browser = page.driver.browser
  browser.switch_to.frame(iframe_name)
  step(step)
  browser.switch_to.default_content
end

When /^(?:|I )click the toolbar button named "(.*?)"$/ do |action_name|
  find('.toolbar-container').click_button action_name
end

When /^(?:|I )choose "(.*?)" from the toolbar "(.*?)" dropdown$/ do |action_name, dropdown_id|
  find("button[has-dropdown-menu][target=#{dropdown_id}DropdownMenu]").click
  find("##{dropdown_id}Dropdown").click_link action_name
end

# that's capybara's old behaviour: clicking the first button that matches
When /^(?:|I )click on the first button matching "([^"]*)"$/ do |button|
  first(:button, button).click
end

When /^(?:|I )follow the first link matching "([^"]*)"$/ do |link|
  first(:link, link).click
end

When /^(?:|I )click on the first anchor matching "([^"]*)"$/ do |anchor|
  find(:xpath, "(//a[text()='#{anchor}'])[1]").click
end

def find_lowest_containing_element(text, selector)
  elements = []

  node_criteria = "[contains(normalize-space(.), \"#{text}\") and not(self::script) and not(child::*[contains(normalize-space(.), \"#{text}\")])]"

  if selector
    search_string = Nokogiri::CSS.xpath_for(selector).first + "//*#{node_criteria}"
    search_string += ' | ' + Nokogiri::CSS.xpath_for(selector).first + "#{node_criteria}"
  else
    search_string = "//*#{node_criteria}"
  end
  elements = all(:xpath, search_string)

rescue Nokogiri::CSS::SyntaxError
  elements
end

require 'timeout'

def wait_until(seconds = 5, options = {}, &block)
  unless options[:i_know_im_immoral]
    raise "You are immoral. I can't stand this. Goodbye.

You really shouldn't use wait_until and wait for an element
using Capybara instead, e.g. using page.should have_selector(...)
See http://www.elabs.se/blog/53-why-wait_until-was-removed-from-capybara
"
    end
  Timeout.timeout(seconds, &block)
end

When /^I confirm popups$/ do
  page.driver.browser.switch_to.alert.accept
end

# Needs Selenium!
Then(/^I should( not )?see a(?:n) alert dialog$/) do |negative|
  negative = !!negative
  if Capybara.current_driver.to_s.include?('selenium')
    begin
      page.driver.browser.switch_to.alert
      expect(negative).to eq(false)
    rescue Selenium::WebDriver::Error::NoSuchAlertError
      expect(negative).to eq(true)
    end
  end
end

Then(/^I should see a confirm dialog$/) do
  page.should have_selector('#confirm_dialog')
end

Then /^I confirm the JS confirm dialog$/ do
  page.driver.browser.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError
end

Then /^I should see a JS confirm dialog$/ do
  page.driver.browser.switch_to.alert.text.should_not be_nil
  page.driver.browser.switch_to.alert.accept
end
