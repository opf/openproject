# frozen_string_literal: true

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

module ResourceManagement
  class GlobalMenu < Menu
    def initialize(params: nil)
      super(project: nil, params:)
    end

    def menu_items
      [staffing_group, *global_planner_groups, *project_groups].compact
    end

    def staffing_group
      return unless User.current.allowed_in_any_project?(:assign_users_to_generic_allocations)

      menu_group(header: nil, children: [staffing_item])
    end

    def staffing_item
      OpenProject::Menu::MenuItem.new(
        title: I18n.t("resource_management.staffing.menu_item"),
        href: staffing_path(project),
        selected: params[:origin_controller] == "resource_management/staffing"
      )
    end

    private

    # The inherited `base_scope` carries a nil project and so resolves to the
    # project-independent planners.
    def global_planner_groups
      return [] unless User.current.allowed_globally?(:view_global_resource_planners)

      [
        populated_group(I18n.t("resource_management.sidebar.public"), public_planners),
        populated_group(I18n.t("resource_management.sidebar.private"), private_planners)
      ]
    end

    def project_groups
      planners_by_project.map do |project, planners|
        menu_group(header: project.name, children: planners.map { |planner| planner_item(planner) })
      end
    end

    # `visible` only separates public from own planners, so the projects the user
    # may see resource planners in have to be intersected explicitly.
    def planners_by_project
      ResourcePlanner
        .visible(User.current)
        .where(project: Project.allowed_to(User.current, :view_resource_planners))
        .with_favorited_by_user(User.current)
        .includes(:project)
        .order(favorited: :desc, name: :asc)
        .group_by(&:project)
        .sort_by { |project, _| project.lft }
    end

    def populated_group(header, children)
      menu_group(header:, children:) if children.any?
    end
  end
end
