# frozen_string_literal: true

# -- copyright
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
# ++

module Grids
  module Widgets
    class Subitems < Grids::WidgetComponent
      include OpPrimer::ComponentHelpers
      include Rails.application.routes.url_helpers

      SUBITEMS_LIMIT = 10
      private_constant :SUBITEMS_LIMIT

      param :project

      option :limit, default: -> { SUBITEMS_LIMIT }

      def title
        t(".title")
      end

      def displayed_subitems
        subitems_with_more.first
      end

      def has_more_subitems?
        subitems_with_more.last
      end

      def has_subitems?
        displayed_subitems.any?
      end

      def can_create_sub_programs?
        project.portfolio? && can_create_sub_projects?
      end

      def can_create_sub_projects?
        @can_create_sub_projects ||= User.current.allowed_in_project?(:add_subprojects, @project)
      end

      def create_sub_program_path
        new_program_path(parent_id: project.id)
      end

      def create_sub_project_path
        new_project_path(parent_id: project.id)
      end

      def can_view_subprojects?
        return false unless current_user.allowed_in_project?(:view_project, project)

        subprojects = project.children

        return true if subprojects.none?

        subprojects.any? do |child|
          current_user.allowed_in_project?(:view_project, child)
        end
      end

      def can_manage_subprojects?
        current_user.allowed_in_project?(:add_subprojects, project)
      end

      private

      def subitems_with_more
        @subitems_with_more ||= project.children
         .visible(current_user)
         .unscope(:order)
         .newest
         .extending(FinderMethods::WithMore)
         .first_with_more(limit)
      end

      def view_all_subitems_path
        @view_all_subitems_path ||= projects_path(filters: project_query_filters)
      end

      def project_query_filters
        [
          { active: { operator: "=", values: ["t"] } },
          { parent_id: { operator: "=", values: [project.id] } }
        ].to_json
      end
    end
  end
end
