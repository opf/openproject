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

Given /^the [pP]roject "([^\"]*)" has the parent "([^\"]*)"$/ do |child_name, parent_name|
  parent = Project.find_by(name: parent_name)
  child = Project.find_by(name: child_name)

  child.set_parent!(parent)
  child.save!
end

Given /^there are the following colors:$/ do |table|
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:color, type_attributes)
  end
end

Given /^I am working in the [tT]imeline "([^"]*)" of the project called "([^"]*)"$/ do |timeline_name, project_name|
  @project = Project.find_by(name: project_name)
  @timeline_name = timeline_name
end

Given /^there are the following reported project statuses:$/ do |table|
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:reported_project_status, type_attributes)
  end
end

Given /^there are the following project types:$/ do |table|
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:project_type, type_attributes)
  end
end

Given /^there are the following projects of type "([^"]*)":$/ do |project_type_name, table|
  table.raw.flatten.each do |name|
    step %{there is a project named "#{name}" of type "#{project_type_name}"}
  end
end

Given /^there are the following project associations:$/ do |table|
  table = table.map_headers { |h| h.delete(' ').underscore }

  table.map_column!('project_a') do |name| Project.find_by!(name: name) end
  table.map_column!('project_b') do |name| Project.find_by!(name: name) end

  table.hashes.each do |type_attributes|
    FactoryGirl.create(:project_association, type_attributes)
  end
end

Given /^there are the following reportings:$/ do |table|
  table = table.map_headers { |h| h.delete(' ').underscore }

  table.hashes.each do |attrs|
    attrs['project'] = Project.find_by!(name: attrs['project'])
    attrs['reporting_to_project'] = Project.find_by!(name: attrs['reporting_to_project'])
    FactoryGirl.create(:reporting, attrs)
  end
end

Given /^there is a timeline "([^"]*)" for project "([^"]*)"$/ do |timeline_name, project_name|
  project = Project.find_by(name: project_name)

  timeline = FactoryGirl.create(:timeline, project_id: project.id, name: timeline_name)
  timeline.options = { 'initial_outline_expansion' => ['6'], 'timeframe_end' => '', 'timeframe_start' => '', 'zoom_factor' => ['-1'], 'exist' => '' }
  timeline.save!
end

Given /^the following types are enabled for projects of type "(.*?)"$/ do |project_type_name, type_name_table|
  project_type = ProjectType.find_by(name: project_type_name)
  projects = Project.where(project_type_id: project_type.id)
  types = type_name_table.raw.flatten.map { |type_name|
    ::Type.find_by(name: type_name) || FactoryGirl.create(:type, name: type_name)
  }

  projects.each do |project|
    project.types = types
    project.save
  end
end

Given (/^there are the following work packages(?: in project "([^"]*)")?:$/) do |project_name, table|
  project = get_project(project_name)
  create_work_packages_from_table table, project
end

def create_work_packages_from_table(table, project)
  table = table.map_headers { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|
    [['author', User],
     ['responsible', User],
     ['assigned_to', User],
     ['type', ::Type],
     ['fixed_version', Version],
     ['priority', IssuePriority],
     ['status', Status],
     ['parent', WorkPackage]
    ].each do |key, const|
      if type_attributes[key].present?
        type_attributes[key] = InstanceFinder.find(const, type_attributes[key])
      else
        type_attributes.delete(key)
      end
    end

    # Force project to have a type the WP can use
    if project.types.empty?
      project.types << FactoryGirl.create(:type_standard)
      project.save!
    end

    # lookup the type by its name and replace it with the type
    # if the cast is ommitted, the contents of type_attributes is interpreted as an int
    if type_attributes.has_key? :type
      type_attributes[:type] = ::Type.find_by(name: type_attributes[:type])
    end

    if type_attributes.has_key? 'author'
      User.current = type_attributes['author']
    end

    FactoryGirl.create(:work_package, type_attributes.merge(project_id: project.id))
  end
end
