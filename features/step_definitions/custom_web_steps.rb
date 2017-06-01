#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

Then /^I should (not )?see "([^"]*)"\s*\#.*$/ do |negative, name|
  steps %{
    Then I should #{negative}see "#{name}"
  }
end

Then /^I should find "([^"]*)"$/ do |element|
  find(element)
end

When /^I click(?:| on) hidden "([^"]*)"$/ do |name|
  # I had no luck with find(name, visible: false).click.
  # Capybara still complained about the element not being visible.
  # That's why I reverted to using JavaScript directly...
  page.evaluate_script("jQuery('#{name}').trigger('click')")
end

When /^I click(?:| on) "([^"]*)"$/ do |name|
  click_link_or_button(name)
end

When /^I click(?:| on) the div "([^"]*)"$/ do |name|
  find("##{name}").click
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, select_id|
  expect(find_field(select_id).value).to eql(value)
end

When /^I hover over "([^"]+)"$/ do |selector|
  page.driver.browser.action.move_to(page.find(selector).native).perform
end

# This moves the mouse to the OP header logo
When /^I stop hovering over "([^"]*)"$/ do |_selector|
  page.driver.browser.action.move_to(page.find('#logo').native).perform
end

When /^I press the "([^"]*)" key on element "([^"]*)"$/ do |key, element|
  press_key_on_element(key.to_sym, element)
end

When /^I focus the element "([^"]*)"$/ do |element|
  # moving to an element triggers focus on it as well
  step %{I hover over "#{element}"}
end
