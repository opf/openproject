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
# frozen_string_literal: true

require "open_project/plugins"

module OpenProject::Screens
  class Engine < ::Rails::Engine
    engine_name :openproject_screens

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-screens",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :admin_menu,
           :screens,
           { controller: "/admin/screens", action: :index },
           if: ->(_) { User.current.admin? },
           caption: :"screens.admin.plural",
           parent: :admin_work_packages

      menu :project_menu,
           :settings_screen_scheme,
           { controller: "/projects/settings/screen_scheme", action: :show },
           if: ->(project) { User.current.allowed_in_project?(:assign_screen_scheme, project) },
           caption: :"screens.project_settings.title",
           parent: :settings

      project_module nil do
        permission :assign_screen_scheme,
                   { "projects/settings/screen_scheme": %i[show update] },
                   permissible_on: :project,
                   require: :member
      end
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Screens::ScreensAPI
      mount ::API::V3::Screens::ScreenSchemesAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::Screens::ProjectScreensAPI
    end

    add_api_path :screens do
      "#{root}/screens"
    end

    add_api_path :screen do |id|
      "#{screens}/#{id}"
    end

    add_api_path :screen_layout do |id|
      "#{screen(id)}/layout"
    end

    add_api_path :screen_sections do |screen_id|
      "#{screen(screen_id)}/sections"
    end

    add_api_path :screen_section do |screen_id, section_id|
      "#{screen_sections(screen_id)}/#{section_id}"
    end

    add_api_path :screen_items do |screen_id|
      "#{screen(screen_id)}/items"
    end

    add_api_path :screen_item do |screen_id, item_id|
      "#{screen_items(screen_id)}/#{item_id}"
    end

    add_api_path :screen_schemes do
      "#{root}/screen_schemes"
    end

    add_api_path :screen_scheme do |id|
      "#{screen_schemes}/#{id}"
    end

    add_api_path :project_screen_scheme do |project_id|
      "#{project(project_id)}/screen_scheme"
    end

    add_api_path :project_type_screen_layout do |project_id, type_id, context|
      "#{project(project_id)}/types/#{type_id}/screens/#{context}"
    end

    config.to_prepare do
      OpenProject::Screens.assert_core_dependencies!
    end
  end
end
