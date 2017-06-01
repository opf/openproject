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

# "Then I should see 5 articles"
Then /^I should see (\d+) ([^\" ]+)?$/ do |number, name|
  page.should have_css(".#{name.singularize}", count: number.to_i)
end

Then /^I should not see(?: (\d+))? ([^\" ]+)$/ do |number, name|
  options = number ? { count: number.to_i } : {}
  page.should have_no_css(".#{name.singularize}", options)
end

Given /^the [pP]roject(?: "([^\"]+?)")? uses the following types:$/ do |project, table|
  project = get_project(project)

  types = table.raw.map { |line|
    name = line.first
    type = ::Type.find_by(name: name)

    type = FactoryGirl.create(:type, name: name) if type.blank?
    type
  }

  project.update_attributes type_ids: types.map(&:id).map(&:to_s)
end

Then(/^I should see the following fields:$/) do |table|
  table.raw.each do |field, value|
    # enforce matches including the value only if it is provided
    # i.e. the column in the table is created

    if value

      begin
        found = find_field(field)
      rescue Capybara::ElementNotFound
        raise Capybara::ExpectationNotMet, "expected to find field \"#{field}\" but there were no matches."
      end

      if found.tag_name == 'select' && value.present?
        should have_select(field, selected: value)
      else
        found.value.should == value
      end
    else
      should have_field(field)
    end
  end
end

Then(/^"([^"]*)" should be the first row in table$/) do |name|
  should have_selector('table.generic-table tbody tr td', text: Regexp.new("#{name}"))
end

When(/^I click link "(.*?)"$/) do |selector|
  page.find(:css, selector).click
end
