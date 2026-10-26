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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"

require_relative "patches/api/work_package_representer"

module OpenProject::SquashTMIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_squashtm_integration

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "openproject_squashtm_integration.inflections" do
      ActiveSupport::Inflector.inflections(:en) do |inflect|
        inflect.acronym "SquashTM"
      end

      OpenProject::Inflector.rule do |basename, abspath|
        parts = basename.split("_")
        next unless parts.include?("squashtm")

        parts.map { |part| part == "squashtm" ? "SquashTM" : default_inflect(part, abspath) }.join
      end
    end

    register "openproject-squashtm_integration",
             author_url: "https://www.openproject.org",
             bundled: true do
      menu :admin_menu,
           :admin_squashtm_integration,
           { controller: "/squashtm_integration/admin/servers", action: :show },
           parent: :admin_integrations,
           if: ->(_) { User.current.admin? },
           caption: "SquashTM",
           icon: :beaker

      menu :project_menu,
           :settings_squashtm,
           { controller: "/squashtm_integration/project_settings/project_links", action: :show },
           parent: :settings,
           caption: :project_module_squashtm

      menu :work_package_split_view,
           :squashtm,
           { tab: :squashtm },
           skip_permissions_check: true,
           after: :relations,
           if: ->(project) {
             User.current.allowed_in_project?(:view_squashtm_test_results, project)
           }

      project_module(:squashtm, dependencies: :work_package_tracking) do
        permission :view_squashtm_test_results,
                   { work_package_squashtm_tab: %i[index] },
                   permissible_on: :project,
                   dependencies: :view_work_packages

        permission :manage_squashtm_links,
                   { "squashtm_integration/work_package_requirement_links": %i[update destroy_dialog destroy] },
                   permissible_on: :project,
                   dependencies: :view_squashtm_test_results

        permission :manage_squashtm_integration,
                   { "squashtm_integration/project_settings/project_links": %i[show update destroy_dialog destroy] },
                   permissible_on: :project,
                   require: :member
      end
    end

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::SquashTMIntegration::Patches::API::WorkPackageRepresenter.extension)
  end
end
