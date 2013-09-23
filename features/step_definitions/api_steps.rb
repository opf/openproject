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

require "benchmark"

When(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" without any filters$/) do |project_name, format|

  @project = Project.find(project_name)
  @unfiltered_benchmark = Benchmark.measure("Unfiltered Results") do
    visit api_v2_project_planning_elements_path(project_id: project_name, format: format)
  end

end

Then(/^the json\-response should include (\d+) work package(s?)$/) do |number_of_wps, plural|
  expect(work_package_names.size).to eql number_of_wps.to_i
end

Then(/^the json\-response should( not)? contain a work_package "(.*?)"$/) do |negation, work_package_name|
  if negation
    expect(work_package_names).not_to include work_package_name
  else
    expect(work_package_names).to include work_package_name
  end

end

And(/^the json\-response should say that "(.*?)" is parent of "(.*?)"$/) do |parent_name, child_name|
  child = decoded_json["planning_elements"].select {|wp| wp["name"] == child_name}.first
  expect(child["parent"]["name"]).to eql parent_name
end

And(/^the json\-response should say that "(.*?)" has no parent$/) do |child_name|
  child = decoded_json["planning_elements"].select {|wp| wp["name"] == child_name}.first
  expect(child["parent"]).to be_nil
end

And(/^the json\-response should say that "(.*?)" has (\d+) child(ren)?$/) do |parent_name, nr_of_children,plural|
  parent = decoded_json["planning_elements"].select {|wp| wp["name"] == parent_name}.first
  expect(parent["children"].size).to eql nr_of_children.to_i
end


When(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" filtering for status "(.*?)"$/) do |project_name, format, status_names|
  statuses = IssueStatus.where(name: status_names.split(','))

  get_filtered_json(project_name: project_name,
                    format: format,
                    filters: [:status_id],
                    operators:  {status_id: "="},
                    values: {status_id: statuses.map(&:id)} )
end

Then(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" filtering for type "(.*?)"$/) do |project_name, format, type_names|
  types = Project.find_by_identifier(project_name).types.where(name: type_names.split(","))

  get_filtered_json(project_name: project_name,
                    format: format,
                    filters: [:type_id],
                    operators:  {type_id: "="},
                    values: {type_id: types.map(&:id)} )


end

When(/^I call the work_package\-api on project "(.*?)" requesting format "(.*?)" filtering for responsible "(.*?)"$/) do |project_name, format, responsible_names|
  responsibles = User.where(login: responsible_names.split(','))

  get_filtered_json(project_name: project_name,
                    format: format,
                    filters: [:responsible_id],
                    operators:  {responsible_id: "="},
                    values: {responsible_id: responsibles.map(&:id)} )

end


And(/^there are (\d+) work packages of type "(.*?)" in project "(.*?)"$/) do |nr_of_wps, type_name, project_name|
  project = Project.find_by_identifier(project_name)
  type = project.types.find_by_name(type_name)

  FactoryGirl.create_list(:work_package, nr_of_wps.to_i, project: project, type: type)

end


And(/^the time to get the unfiltered results should not exceed (\d+)\.(\d+)s$/) do |seconds,milliseconds|
  puts "----Unfiltered Benchmark----"
  puts @unfiltered_benchmark
  @unfiltered_benchmark.total.should < "#{seconds}.#{milliseconds}".to_f
end

And(/^the time to get the filtered results should not exceed (\d+)\.(\d+)s$/) do |seconds, milliseconds|
  puts "----Filtered Benchmark----"
  puts @filtered_benchmark
  @filtered_benchmark.total.should < "#{seconds}.#{milliseconds}".to_f
end

Then(/^the time to get the filtered results should be faster than the time to get the unfiltered results$/) do
  @filtered_benchmark.total.should < @unfiltered_benchmark.total
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

def get_filtered_json(params)
  @filtered_benchmark = Benchmark.measure("Filtered Results") do
    visit api_v2_project_planning_elements_path(project_id: params[:project_name],
                                                format: params[:format],
                                                f: params[:filters],
                                                op: params[:operators],
                                                v: params[:values])
  end
end
