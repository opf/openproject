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

Given (/^there are the following work packages(?: in project "([^"]*)")?:$/) do |project_name, table|
  project = get_project(project_name)
  table.map_headers! { |header| header.underscore.gsub(' ', '_') }

  table.hashes.each do |type_attributes|

    [
      ["author", User],
      ["responsible", User],
      ["assigned_to", User],
      ["type", Type],
      ["fixed_version", Version],
      ["priority", IssuePriority],
      ["status", Status],
      ["parent", WorkPackage]
    ].each do |key, const|
      if type_attributes[key].present?
        type_attributes[key] = InstanceFinder.find(const, type_attributes[key])
      else
        type_attributes.delete(key)
      end
    end

    # lookup the type by its name and replace it with the type
    # if the cast is ommitted, the contents of type_attributes is interpreted as an int
    unless type_attributes.has_key? :type
      type_attributes[:type] = Type.where(name: type_attributes[:type].to_s).first
    end

    factory = FactoryGirl.create(:work_package, type_attributes.merge(:project_id => project.id))
  end
end
