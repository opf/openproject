#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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

When /^I click(?:| on) "([^"]*)"$/ do |name|
  click_link_or_button(name)
end

When /^I click(?:| on) the div "([^"]*)"$/ do |name|
  find("##{name}").click
end

When /^(?:|I )jump to [Pp]roject "([^\"]*)"$/ do |project|
  click_link('Projects')
  # supports both variants of finding: by class and by id
  # id is older and can be dropped later
  project_div = find(:css, '.project-search-results', text: project) || find(:css, '#project-search-results', text: project)

  page.execute_script("window.location = jQuery(\"##{project_div[:id]} div[title='#{project}']\").parent().data('select2Data').project.url;")
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, select_id|
  # that makes capybara wait for the ajax request
  find(:xpath, '//body')
  # if you wanna see ugly things, look at the following line
  (page.evaluate_script("$('#{select_id}').value") =~ /^#{value}$/).should be_present
end

Then /^"([^"]*)" should (not )?be selectable from "([^"]*)"$/ do |value, negative, select_id|
  # more page.evaluate ugliness
  find(:xpath, '//body')
  bool = !negative
  (page.evaluate_script("$('#{select_id}').select('option[value=#{value}]').first.disabled") =~ /^#{bool}$/).should be_present
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
