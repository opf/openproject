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

object @project

attributes :id, :name, :identifier, :description, :project_type_id

node :permissions do |project|
  { view_planning_elements: User.current.allowed_to?(:view_work_packages, project),
    edit_planning_elements: User.current.allowed_to?(:edit_work_packages, project),
    delete_planning_elements: User.current.allowed_to?(:delete_work_packages, project)
  }
end


node :parent, if: lambda{|project| visible_parent_project(project).present?} do |project|
  child :parent do
    attributes :id, :name, :identifier
  end

end

node :responsible, if: lambda{|project| project.responsible.present?} do |project|
  {id: project.responsible.id, name: project.responsible.name}
end

node :project_type, if: lambda{|project| project.project_type.present?} do |project|
  {id: project.project_type.id, name: project.project_type.name}
end


node :created_on, if: lambda{|project| project.created_on.present?} {|project| project.created_on.utc.iso8601}
node :updated_on, if: lambda{|project| project.updated_on.present?} {|project| project.updated_on.utc.iso8601}

node :types, if: lambda{|project| project.types.present? } do |project|
  project.types.map do |type|
    type_hash = {id: type.id,
                 name: type.name,
                 is_milestone: type.is_milestone?}
    type_hash[:color] = {id: type.color.id, name: type.color.name, hexcode: type.color.hexcode} if type.color.present?
    type_hash
  end
end

node :project_associations, unless: lambda{|project| project.project_associations.visible.empty?} do |project|
  project.project_associations.visible.map do |project_association|
    other_project = project_association.project(project)
    {id: project_association.id,
     project: {id: other_project.id,
               identifier: other_project.identifier,
               name: other_project.name}
    }
  end
end

node :parent, if: lambda{|project| visible_parent_project(project).present?} do |project|
  parent = visible_parent_project(project)
  { id: parent.id, name: parent.name, identifier: parent.identifier }
end

node :custom_fields do
  partial "api/v2/custom_fields/values", :object => (locals[:object] || @project).custom_values
end
