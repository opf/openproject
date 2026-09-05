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
# ++

module Backlogs
  module SprintReports
    module Widgets
      class CreatedResolvedChart < Grids::WidgetComponent
        include Redmine::I18n

        param :sprint
        param :project

        def title
          t("backlogs.show_created_resolved_chart")
        end

        def chart_data
          {
            labels: xaxis_labels(created_resolved),
            datasets: dataseries(created_resolved)
          }.to_json
        end

        def wrapper_arguments
          { full_width: true }
        end

        private

        def created_resolved
          return nil unless sprint.date_range_set?

          @created_resolved ||= CreatedResolved.new(sprint, project)
        end

        def xaxis_labels(created_resolved)
          # 14 entries (plus the axis label) have come along as the best value for a good optical result.
          # Thus it is enough space between the entries.
          entries_displayed = (created_resolved.days.length / 14.0).ceil
          created_resolved.days.enum_for(:each_with_index).map do |d, i|
            if (i % entries_displayed) == 0
              ["#{format_date(d, format: I18n.t("date.formats.short"))}"]
            end
          end
        end

        def dataseries(created_resolved)
          created_resolved.series.map do |s|
            Rails.logger.info ">>> DEBUG series: #{s.inspect}"
            {
              label: I18n.t("created_resolved.#{s.first}"),
              data: s.last.enum_for(:each)
            }
          end
        end
      end
    end
  end
end
