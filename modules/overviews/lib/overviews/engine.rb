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

module Overviews
  class Engine < ::Rails::Engine
    engine_name :overviews

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "overviews.menu" do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:overview,
                  { controller: "/overviews/overviews", action: "show" },
                  caption: :"overviews.label",
                  first: true,
                  icon: "info")
      end
    end

    initializer "overviews.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:view_project)
          .controller_actions
          .push(
            "overviews/overviews/show"
          )

        OpenProject::AccessControl.permission(:view_project_attributes)
          .controller_actions
          .push(
            "overviews/overviews/project_custom_fields_sidebar"
          )

        OpenProject::AccessControl.permission(:edit_project_attributes)
          .controller_actions
          .push(
            "overviews/overviews/project_custom_field_section_dialog",
            "overviews/overviews/update_project_custom_values"
          )

        OpenProject::AccessControl.permission(:view_work_packages)
          .controller_actions
          .push(
            "overviews/overviews/show"
          )

        OpenProject::AccessControl.map do |ac_map|
          ac_map.project_module nil do |map|
            map.permission :manage_overview,
                           { "overviews/overviews":
                              [
                                "show"
                              ] },
                           permissible_on: :project,
                           require: :member
          end
        end
      end
    end

    initializer "overviews.conversion" do
      require Rails.root.join("config/constants/ar_to_api_conversions")

      Constants::ARToAPIConversions.add("grids/overview": "grid")
    end

    config.to_prepare do
      Overviews::GridRegistration.register!
    end
  end
end
