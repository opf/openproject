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

class WorkPackages::SetAttributesService
  module ProgressValuesCalculations
    # Calculate work from remaining work and percent complete without checking for consistency.
    # It returns unexpected results when `percent_complete` is 100.
    def calculate_work(remaining_work:, percent_complete:)
      remaining_percent_complete = 1.0 - (percent_complete / 100.0)
      (remaining_work / remaining_percent_complete).round(2)
    end

    # Calculate remaining work from work and percent complete without checking for consistency.
    def calculate_remaining_work(work:, percent_complete:)
      completed_work = work * percent_complete / 100.0
      remaining_work = (work - completed_work).round(2)
      remaining_work.clamp(0.0, work)
    end

    # Calculate percent complete from work and remaining work without checking for consistency.
    # Raises `FloatDomainError` if work is 0.
    def calculate_percent_complete(work:, remaining_work:)
      # round to 2 decimal places because that's how we store work and remaining
      # work in database
      rounded_work = work.round(2)
      rounded_remaining_work = remaining_work.round(2)
      completed_work = rounded_work - rounded_remaining_work
      completion_ratio = completed_work.to_f / rounded_work

      percentage = (completion_ratio * 100)
      case percentage
      in 0 then 0
      in 0..1 then 1
      in 99...100 then 99
      else
        percentage.round
      end
    end

    # Check if the remaining work value is wrong and can be corrected regarding
    # work and % complete values.
    #
    # In most cases, it's not remaining work but % complete which must change.
    # The only case where remaining work must be corrected is when work is set,
    # % complete is 100% and remaining work is not 0h. In this case this method
    # returns `true`.
    def correctable_remaining_work_value?(work:, remaining_work:, percent_complete:)
      work.present? && remaining_work != 0 && percent_complete == 100
    end

    # Check if the % complete value is wrong and can be corrected regarding work
    # and remaining work values.
    #
    # Returns `false` if the percent complete is the same as the one calculated
    # from work and remaining work, or if the remaining work is the same as the
    # one calculated from work and percent complete.
    #
    # Returns `false` also if the percent complete value cannot be calculated
    # because other values are missing or out of bounds.
    #
    # Returns `false` also in the special case where % complete is 100% and
    # remaining work greater than 0h. In this case, it's remaining work which needs to
    # be corrected to 0h.
    def correctable_percent_complete_value?(work:, remaining_work:, percent_complete:)
      return false unless percent_complete_calculation_applicable?(work:, remaining_work:, percent_complete:)

      # Check if one of provided remaining_work or percent_complete matches the calculated one
      percent_complete != calculate_percent_complete(work:, remaining_work:) \
        && remaining_work != calculate_remaining_work(work:, percent_complete:)
    end

    def percent_complete_calculation_applicable?(work:, remaining_work:, percent_complete:)
      WorkPackage.work_based_mode? && # only applicable in work-based mode
        work && remaining_work && percent_complete && # only applicable if all 3 values are set
        work != 0 && # only applicable if not leading to divisions by zero
        percent_complete != 100 && # keep 100% complete as is
        remaining_work >= 0 && work >= remaining_work # only applicable if positive and work is greater than remaining work
    end
  end
end
