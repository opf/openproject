#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module API
  module V3
    module Projects
      class ProjectEagerLoadingWrapper < API::V3::Utilities::EagerLoading::EagerLoadingWrapper
        include API::V3::Utilities::EagerLoading::CustomFieldAccessor

        # delegate class check to wrapped object, as there are cases where the type is checked explicitly.
        delegate :is_a?, to: :__getobj__

        class << self
          def wrap(projects)
            if projects.present?
              custom_fields_by_project_id = custom_fields_from_projects

              ancestors = ancestor_projects(projects)
            end

            super
              .each do |project|
              project.available_custom_fields = custom_fields_by_project_id[project.id]
              project.ancestors_from_root = ancestors.select { |a| a.is_ancestor_of?(project) }.sort_by(&:lft)
            end
          end

          def ancestor_projects(projects)
            ancestor_selector = projects[1..].inject(ancestor_project_select(projects[0])) do |select, project|
              select.or(ancestor_project_select(project))
            end
            Project.where(ancestor_selector).to_a
          end

          def ancestor_project_select(project)
            projects_table = Project.arel_table

            projects_table[:lft].lt(project.lft).and(projects_table[:rgt].gt(project.rgt))
          end

          def custom_fields_from_projects
            ProjectCustomFieldProjectMapping
              .eager_load(:project_custom_field)
              .merge(ProjectCustomField.visible)
              .where(project_id: Project.allowed_to(User.current, :view_project_attributes))
              .each_with_object(Hash.new { |h, k| h[k] = [] }) do |mapping, acc|
                acc[mapping.project_id] << mapping.project_custom_field
              end
          end
        end
      end
    end
  end
end
