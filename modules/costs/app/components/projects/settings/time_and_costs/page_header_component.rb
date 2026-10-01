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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  module Settings
    module TimeAndCosts
      class PageHeaderComponent < ApplicationComponent
        def initialize(project:, selected:, **)
          @project = project
          @selected = selected
          super(project, **)
        end

        def tabs
          [
            {
              name: :time_entry_activities,
              path: helpers.project_settings_time_entry_activities_path(@project),
              label: I18n.t(:enumeration_activities)
            },
            {
              name: :cost_types,
              path: helpers.project_settings_cost_types_path(@project),
              label: I18n.t("cost_types.settings.cost_types.heading")
            }
          ]
        end

        def page_title
          I18n.t("cost_types.settings.time_and_costs")
        end

        def breadcrumbs_items
          [
            { href: helpers.project_overview_path(@project.id), text: @project.name },
            { href: helpers.project_settings_general_path(@project.id), text: I18n.t(:label_project_settings) },
            page_title
          ]
        end
      end
    end
  end
end
