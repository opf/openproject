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

collection @projects => "projects"
attributes :id,
           :name,
           :identifier,
           :description,
           :project_type_id,
           :parent_id,
           :responsible_id


node :type_ids, if: lambda{|project| project.types.present? } do |project|
  project.types.map(&:id)
end

node :project_associations, if: lambda{|project| has_associations?(project)} do |project|
  associations_for_project(project).map do |association|
    other_id = [association.project_a_id, association.project_b_id].find { |id| id != project.id }

    {id: association.id,
     to_project_id: other_id,
     description: association.description}
  end
end

node :created_on, if: lambda{|project| project.created_on.present?} {|project| project.created_on.utc.iso8601}
node :updated_on, if: lambda{|project| project.updated_on.present?} {|project| project.updated_on.utc.iso8601}
