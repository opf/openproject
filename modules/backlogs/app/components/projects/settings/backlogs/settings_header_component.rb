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

module Projects
  module Settings
    module Backlogs
      class SettingsHeaderComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers

        def initialize(project:, selected_tab:)
          super

          @project = project
          @selected_tab = selected_tab
        end

        def selected_tab?(tab_name)
          selected_tab == tab_name
        end

        def tabs
          [
            types_and_statuses_tab,
            sharing_tab,
            multiple_active_sprints_tab,
            estimation_unit_tab
          ].compact
        end

        private

        attr_reader :project, :selected_tab

        def types_and_statuses_tab
          {
            key: :types_and_statuses,
            href: project_settings_backlogs_path(project),
            label: t("backlogs.types_and_statuses")
          }
        end

        def sharing_tab
          return unless User.current.allowed_in_project?(:share_sprint, project)

          {
            key: :sharing,
            href: project_settings_backlog_sharing_path(project),
            label: t("backlogs.sharing")
          }
        end

        def multiple_active_sprints_tab
          return unless User.current.allowed_in_project?(:share_sprint, project)

          {
            key: :multiple_active_sprints,
            href: project_settings_backlog_multiple_active_sprints_path(project),
            label: t("backlogs.multiple_active_sprints")
          }
        end

        def estimation_unit_tab
          return unless show_unit_tab?

          {
            key: :estimation_unit,
            href: project_settings_backlog_estimation_unit_path(project),
            label: t("backlogs.estimation_unit")
          }
        end

        def show_unit_tab?
          User.current.allowed_in_project?(:select_backlog_types_and_statuses, project) &&
            OpenProject::FeatureDecisions.project_settings_estimation_unit_active?
        end
      end
    end
  end
end
