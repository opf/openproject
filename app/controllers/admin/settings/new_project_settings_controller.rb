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

module Admin::Settings
  class NewProjectSettingsController < ::Admin::SettingsController
    menu_item :new_project_settings

    before_action :validate_enabled_modules, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter

    def default_breadcrumb
      t(:label_project_new)
    end

    private

    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    def validate_enabled_modules
      return if settings_params[:default_projects_modules].blank?

      enabled_modules = settings_params[:default_projects_modules].map(&:to_sym)

      module_missing_deps = OpenProject::AccessControl
        .modules
        .filter_map do |m|
          if m[:dependencies] &&
            enabled_modules.include?(m[:name]) &&
            (m[:dependencies] & enabled_modules) != m[:dependencies]

            I18n.t(
              "settings.projects.missing_dependencies",
              module: I18n.t("project_module_#{m[:name]}"),
              dependencies: m[:dependencies].map { |dep| I18n.t("project_module_#{dep}") }.join(", ")
            )
          end
        end

      if module_missing_deps.any?
        flash[:error] = helpers.list_of_messages(module_missing_deps)

        redirect_to action: :show
      end
    end

    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity
  end
end
