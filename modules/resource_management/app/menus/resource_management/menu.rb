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
  class Menu < Submenu
    def initialize(project: nil, params: nil)
      # ResourcePlanner does not use Query objects, so view_type is irrelevant
      # for our group methods. Pass a placeholder to satisfy the parent.
      super(view_type: "resource_planner", params: params || {}, project:)
    end

    def menu_items
      [
        menu_group(header: I18n.t("resource_management.sidebar.public"),  children: public_planners),
        menu_group(header: I18n.t("resource_management.sidebar.private"), children: private_planners)
      ]
    end

    def public_planners
      base_scope
        .public_views
        .map { |planner| planner_item(planner) }
    end

    def private_planners
      base_scope
        .private_views(User.current)
        .map { |planner| planner_item(planner) }
    end

    private

    # Order favorited items first, then alphabetically. `with_favorited_by_user`
    # adds a virtual `favorited` column so we can both sort by it and read it
    # back without a second query.
    def base_scope
      ResourcePlanner
        .visible(User.current)
        .where(project:)
        .with_favorited_by_user(User.current)
        .order(favorited: :desc, name: :asc)
    end

    def planner_item(planner)
      OpenProject::Menu::MenuItem.new(
        title: planner.name,
        href: project_resource_planner_path(project, planner),
        icon: nil,
        count: nil,
        selected: planner.id.to_s == params[:id].to_s,
        favorited: planner.favorited,
        show_enterprise_icon: false
      )
    end
  end
end
