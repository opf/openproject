#encoding: utf-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

When(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" without any filters$/) do |project_name, format|

  @project = Project.find(project_name)
  visit api_v2_project_planning_elements_path(project_id: project_name, format: format)
end

Then(/^the json\-response should include (\d+) work packages$/) do |number_of_wps|
  expect(work_package_names.size).to eql number_of_wps.to_i
end

Then(/^the json\-response should( not)? contain a work_package "(.*?)"$/) do |negation, work_package_name|
  if negation
    expect(work_package_names).not_to include work_package_name
  else
    expect(work_package_names).to include work_package_name
  end

end

Then(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" filtering for type "(.*?)"$/) do |project_name, format, type_names|
  types = Project.find_by_identifier(project_name).types.where(name: type_names.split(","))

  visit api_v2_project_planning_elements_path(project_id: project_name, format: format, types: types.map(&:id))
end


def work_package_names
  decoded_json["planning_elements"].map{|wp| wp["name"]}
end

def decoded_json
  @decoded_json ||= ActiveSupport::JSON.decode last_json
end

def last_json
  page.source
end
