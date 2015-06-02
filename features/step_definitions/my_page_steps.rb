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

Then /^the "(.+)" widget should be in the top block$/ do |widget_name|
  steps %{Then I should see "#{widget_name}" within "#list-top"}
end

When /^I select "(.+)" from the available widgets drop down$/ do |widget_name|
  steps %{When I select "#{widget_name}" from "block-select"}
end

Then /^I should see the dropdown of available widgets$/ do
  page.has_select?('block-select', options: ['Watched Issues', 'Issues assigned to me'])
end

Then(/^I should see the widget "([^"]*)"$/) do |arg|
  page.find("#block_#{arg}").should_not be_nil
end

Then /^"(.+)" should( not)? be disabled in the my page available widgets drop down$/ do |widget_name, neg|
  option_name = MyController.available_blocks.detect { |_k, v| I18n.t(v) == widget_name }.first.dasherize

  unless neg
    steps %{Then the "block-select" drop-down should have the following options disabled:
              | #{option_name} |}
  else
    steps %{Then the "block-select" drop-down should have the following options enabled:
            | #{option_name} |}
  end

end

When(/^I click the first delete block link$/) do
  all(:xpath, "//a[@title='Remove widget']")[0].click
end
