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

module Backlogs::Concerns
  # Measure progress in the estimation unit selected for the project.
  #
  # Requires `project`, `resolved_value` and `total_value` in the including component.
  module ProgressMetric
    def resolved_percentage
      # Estimated hours are floats, convert to integer minutes for exact division
      resolved, total = [resolved_value, total_value].map { progress_metric == :time ? (it * 60).round : it }
      return 0 if total.zero? || resolved.zero?

      [resolved * 100 / total, 1].max
    end

    def formatted_percentage
      ActiveSupport::NumberHelper.number_to_percentage(resolved_percentage, precision: 0)
    end

    private

    def progress_values
      values = { resolved: resolved_value, count: total_value }
      values.transform_values! { DurationConverter.output(it) } if progress_metric == :time
      values
    end

    def progress_metric
      return :work_packages unless OpenProject::FeatureDecisions.project_settings_estimation_unit_active?

      estimation_metric
    end

    def estimation_metric
      @estimation_metric ||= if project.estimation_unit_time?
                               :time
                             elsif project.estimation_unit_story_points?
                               :story_points
                             else
                               :work_packages
                             end
    end
  end
end
