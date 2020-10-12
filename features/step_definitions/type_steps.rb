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

# change from symbol to constant once namespace is removed

InstanceFinder.register(::Type, Proc.new { |name| ::Type.find_by(name: name) })

RouteMap.register(::Type, '/types')

Given /^the following types are enabled for the project called "(.*?)":$/ do |project_name, type_name_table|
  types = type_name_table.raw.flatten.map { |type_name|
    ::Type.find_by(name: type_name) || FactoryBot.create(:type, name: type_name)
  }

  project = Project.find_by(identifier: project_name)
  project.types = types
  project.save!
end

Then /^I should not see the "([^"]*)" type$/ do |name|
  page.all(:css, '.timelines-pet-name', text: name).should be_empty
end

Then /^I should see the "([^"]*)" type$/ do |name|
  expect(page)
    .to have_selector(:css, '.timelines-pet-name', text: name)
end
