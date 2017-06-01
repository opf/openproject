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

When /^I toggle the "([^"]+)" submenu$/ do |menu_name|
  nodes = all(:css, ".menu_root a[title=\"#{menu_name}\"] + .toggler")

  # w/o javascript, all menu elements are expanded by default. So the toggler
  # might not be present.
  nodes.first.click if nodes.present?
end

Then /^there should be no menu item selected$/ do
  page.should_not have_css('#main-menu .selected')
end

Then /^there should not be a main menu$/ do
  page.should_not have_css('#main-menu')
end

Then /^I should (not )?see "(.*?)" as being logged in$/ do |negative, name|
  if negative
    page.should_not have_link(name)
  else
    page.should have_link(name)
  end
end

# opens a menu item in the main menu
When /^I open the "([^"]+)" (?:sub)?menu$/ do |menu_name|
  nodes = all(:css, ".menu_root a[title=\"#{menu_name}\"]")

  # w/o javascript, all menu elements are expanded by default. So the toggler
  # might not be present.
  nodes.first.click if nodes.present?
end

When /^I select "(.+?)" from the action menu$/ do |entry_name|
  within(action_menu_selector) do
    find('button').click
  end
  within('.dropdown-menu') do
    click_link(entry_name)
  end
end

When /^I click on the edit button$/ do
  within('#toolbar-items') do
    find('.edit-all-button').click
  end
end

Then /^there should not be a "(.+?)" entry in the action menu$/ do |entry_name|
  within(action_menu_selector) do
    should_not have_link(entry_name)
  end
end

def action_menu_selector
  # supports both the old and the new selector for the action menu
  # please note that using this with the old .contextual selector takes longer
  # as capybara waits for the new .action_menu_main selector to appear

  if has_css?('.action_menu_main')
    all('.action_menu_main').first
  elsif has_css?('.action_menu_specific')
    all('.action_menu_specific').first
  elsif has_css?('.contextual')
    all('.contextual').first
  else
    raise 'No action menu on the current page'
  end
end
