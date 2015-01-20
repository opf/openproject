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

InstanceFinder.register(ProjectType, Proc.new { |name| ProjectType.find_by_name(name) })

Given /^the project(?: named "([^"]*)")? has no project type$/ do |name|
  project = get_project(name)
  project.update_attribute(:project_type_id, nil)
end

Given /^the project(?: named "([^"]*)")? is of the type "([^"]*)"$/ do |name, type_name|
  type_id = ProjectType.select(:id).find_by_name(type_name).id
  project = get_project(name)
  project.update_attribute(:project_type_id, type_id)
end

When /^I follow the edit link of the project type "([^"]*)"$/ do |project_type_name|
  type = ProjectType.find_by_name(project_type_name)

  href = Rails.application.routes.url_helpers.edit_project_type_path(type)

  click_link(type.name, href: href)
end
