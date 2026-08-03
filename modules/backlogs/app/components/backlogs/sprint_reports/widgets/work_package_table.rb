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

module Backlogs
  module SprintReports
    module Widgets
      class WorkPackageTable < Grids::WidgetComponent
        include Backlogs::CommonHelper

        param :sprint
        param :project

        def title = t("#{i18n_key}.title", scope: i18n_scope)

        def render?
          EnterpriseToken.allows_to?(:baseline_comparison) &&
          EnterpriseToken.allows_to?(:sprint_report_pro_widgets) &&
          user_allowed?(:view_sprints)
        end

        def show_table? = state == :display

        def wrapper_arguments
          { full_width: true, classes: "op-sprint-report-wp-table" }
        end

        def blankslate_icon = :table

        def blankslate_text(part)
          t("#{i18n_key}.blankslate.#{state}.#{part}", default: :"blankslate.#{part}", scope: i18n_scope)
        end

        def query_props
          {
            filters: filters.to_json,
            "columns[]": %w[id subject type status assigned_to],
            sortBy: [%w[position asc]].to_json,
            showHierarchies: false
          }.tap do |props|
            present = timestamps.compact
            props[:timestamps] = present.join(",") if present.any?(&:historic?)
          end
        end

        def table_configuration
          {
            actionsColumnEnabled: false,
            columnMenuEnabled: false,
            contextMenuEnabled: false,
            inlineCreateEnabled: false
          }
        end

        private

        def state
          @state ||=
            if !sprint.date_range_set?
              :no_dates
            elsif !sprint.started_at?
              :not_started
            elsif empty?
              :empty
            else
              :display
            end
        end

        def i18n_key = raise SubclassResponsibilityError

        def empty? = raise SubclassResponsibilityError

        def i18n_scope = "backlogs.sprint_reports.widgets.work_package_table"

        def filters
          [{ sprintId: { operator: "=", values: [sprint.id.to_s] } }]
        end

        def timestamps = raise SubclassResponsibilityError

        def status_filter(operator)
          { status: { operator:, values: breakdown.done_status_ids.map(&:to_s) } }
        end

        def breakdown
          @breakdown ||= SprintWorkPackageBreakdown.new(sprint:, project:)
        end
      end
    end
  end
end
