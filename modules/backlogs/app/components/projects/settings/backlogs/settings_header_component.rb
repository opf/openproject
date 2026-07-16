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
            {
              key: :types_and_statuses,
              href: project_settings_backlogs_path(project),
              label: t("backlogs.types_and_statuses")
            },
            (if User.current.allowed_in_project?(:share_sprint, project)
               {
                 key: :sharing,
                 href: project_settings_backlog_sharing_path(project),
                 label: t("backlogs.sharing")
               }
             end),
            (if User.current.allowed_in_project?(:share_sprint, project)
               {
                 key: :multiple_active_sprints,
                 href: project_settings_backlog_multiple_active_sprints_path(project),
                 label: t("backlogs.multiple_active_sprints")
               }
             end)
          ].compact
        end

        private

        attr_reader :project, :selected_tab
      end
    end
  end
end
