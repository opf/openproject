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

        def favorited_by?(user)
          return super unless favorite_preloaded_for?(user)

          @preloaded_favorite
        end

        def favorite_preloaded_for?(user)
          defined?(@preloaded_favorite_user) && user == @preloaded_favorite_user
        end
        private :favorite_preloaded_for?

        class << self
          def wrap(projects, favorite_user: nil, eager_loaded: %i[custom_fields ancestors favorites])
            super(projects).tap do |wrapped_projects|
              eager_load_custom_fields(wrapped_projects) if eager_loaded.include?(:custom_fields)
              eager_load_ancestors(wrapped_projects) if eager_loaded.include?(:ancestors)
              eager_load_favorites(wrapped_projects, favorite_user) if favorite_user && eager_loaded.include?(:favorites)
            end
          end

          private

          def eager_load_favorites(projects, favorite_user)
            favorite_project_ids = Favorite
              .where(user: favorite_user, favorited_type: Project.base_class.name, favorited_id: projects.map(&:id))
              .pluck(:favorited_id)
              .index_with { true }

            projects.each do |project|
              project.instance_variable_set(:@preloaded_favorite_user, favorite_user)
              project.instance_variable_set(:@preloaded_favorite, favorite_project_ids.fetch(project.id, false))
            end
          end

          def eager_load_custom_fields(projects)
            custom_fields_by_project_id = custom_fields_from_projects(projects)

            projects.each do |project|
              project.available_custom_fields = custom_fields_by_project_id[project.id]
            end
          end

          def eager_load_ancestors(projects)
            return if projects.empty?

            ancestors = ancestor_projects(projects)

            projects.each do |project|
              project.ancestors_from_root = ancestors.select { |a| a.is_ancestor_of?(project) }.sort_by(&:lft)
            end
          end

          def ancestor_projects(projects)
            projects[1..].inject(ancestor_projects_of(projects[0])) do |select, project|
              select.or(ancestor_projects_of(project))
            end.to_a
          end

          def ancestor_projects_of(project)
            projects_table = Project.arel_table

            Project.where(projects_table[:lft].lt(project.lft).and(projects_table[:rgt].gt(project.rgt)))
          end

          def custom_fields_from_projects(projects)
            ProjectCustomFieldProjectMapping
              .eager_load(:project_custom_field)
              .merge(ProjectCustomField.visible)
              .where(project_id: projects.map(&:id))
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
