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

api.project do
  api.id(project.id)
  api.name(project.name)
  api.identifier(project.identifier)

  api.permissions(
      :view_planning_elements => User.current.allowed_to?(:view_work_packages, project),
      :edit_planning_elements => User.current.allowed_to?(:edit_work_packages, project),
      :delete_planning_elements => User.current.allowed_to?(:delete_work_packages, project)
    )

  # TODO: Evaluate html formatting of description instead of passing the raw
  # textile code - although this is also not done in the official API
  api.description(project.description)

  parent = visible_parent_project(project)
  if parent
    api.parent(:id => parent.id,
               :name => parent.name,
               :identifier => parent.identifier)
  end

  if project.responsible
    api.responsible(:id => project.responsible.id, :name => project.responsible.name)
  end

  if project.project_type
    api.project_type(:id   => project.project_type.id,
                     :name => project.project_type.name)
  end

  planning_element_types = project.types
  if planning_element_types.present?
    api.array :planning_element_types, :size => planning_element_types.size do
      planning_element_types.each do |planning_element_type|
        api.planning_element_type do
          api.id planning_element_type.id
          api.name planning_element_type.name

          color = planning_element_type.color
          if color.present?
            api.color(:id => color.id, :name => color.name, :hexcode => color.hexcode)
          end
          api.is_milestone planning_element_type.is_milestone?
        end
      end
    end
  end

  project_associations = project.project_associations.visible
  if project_associations.present?
    api.array :project_associations, :size => project_associations.size do
      project_associations.each do |project_association|
        api.project_association(:id => project_association.id) do
          other = project_association.project(project)
          api.project(:id         => other.id,
                      :identifier => other.identifier,
                      :name       => other.name)
        end
      end
    end
  end

  api.created_on(project.created_on.utc.iso8601) if project.created_on
  api.updated_on(project.updated_on.utc.iso8601) if project.updated_on
end
