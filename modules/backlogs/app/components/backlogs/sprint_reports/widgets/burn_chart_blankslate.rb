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

module Backlogs
  module SprintReports
    module Widgets
      # Including widgets implement `too_long_to_chart?`, `anything_to_chart?` and
      # `chartable_work_packages`.
      module BurnChartBlankslate
        include ChartBlankslate

        private

        def blankslate_reason
          if too_long_to_chart?
            :too_long
          elsif sprint_begun?
            :"no_#{estimate_column}" unless anything_to_chart?
          elsif estimated_work?
            :not_started
          else
            :"not_started_without_#{estimate_column}"
          end
        end

        # Before the sprint begins nothing has been measured, so what the sprint holds now has to
        # answer in the series' place.
        def estimated_work?
          chartable_work_packages.where(WorkPackage.arel_table[estimate_column].gt(0)).exists?
        end

        def estimate_column = project.estimation_unit_time? ? :estimated_hours : :story_points

        def sprint_begun? = ::Sprints::Timeframe.new(sprint, zone: current_user.time_zone).begun?
      end
    end
  end
end
