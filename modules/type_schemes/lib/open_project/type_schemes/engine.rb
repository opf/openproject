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

module OpenProject::TypeSchemes
  class Engine < ::Rails::Engine
    engine_name :openproject_type_schemes

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-type_schemes",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :admin_menu,
           :type_schemes,
           { controller: "/admin/type_schemes", action: :index },
           if: ->(_) { User.current.admin? },
           caption: :"type_schemes.plural",
           parent: :admin_work_packages

      menu :project_menu,
           :settings_type_scheme,
           { controller: "/projects/settings/type_scheme", action: :show },
           if: ->(project) { User.current.allowed_in_project?(:assign_type_scheme, project) },
           caption: :"type_schemes.project_settings.title",
           parent: :settings

      # Consumed by the project settings page. Deliberately not inside a project_module,
      # so it is usable without enabling a module per project.
      project_module nil do
        permission :assign_type_scheme,
                   { "projects/settings/type_scheme": %i[show update] },
                   permissible_on: :project,
                   require: :member
      end
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::TypeSchemes::TypeSchemesAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::TypeSchemes::ProjectTypeSchemeAPI
    end

    add_api_path :type_schemes do
      "#{root}/type_schemes"
    end

    add_api_path :type_scheme do |id|
      "#{type_schemes}/#{id}"
    end

    add_api_path :project_type_scheme do |project_id|
      "#{project(project_id)}/type_scheme"
    end

    add_api_path :project_available_types do |project_id|
      "#{project(project_id)}/available_types"
    end

    config.after_initialize do
      OpenProject::Notifications.subscribe(OpenProject::Events::PROJECT_CREATED) do |payload|
        OpenProject::TypeSchemes::ProjectCreatedListener.call(payload)
      end
    end

    config.to_prepare do
      ::WorkPackages::BaseContract.prepend(OpenProject::TypeSchemes::ContractPatch)
      ::WorkPackages::SetAttributesService.prepend(OpenProject::TypeSchemes::SetAttributesServicePatch)
    end
  end
end
