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

# Custom matcher to check if remaining work value can be corrected because it is
# inconsistent with work and % complete as returned by
# WorkPackages::SetAttributesService::ProgressValuesCalculations#correctable_remaining_work_value?
#
# The helper helps at outputting the acceptable range of values for the percent
# complete and/or remaining work when it fails.
#
# Usage:
#   # 100% complete and 0h remaining work => good values
#   expect(work: 10, remaining_work: 0, percent_complete: 100)
#     .not_to have_correctable_remaining_work_value
#   # 100% complete and not 0h remaining work=> bad remaining work
#   expect(work: 10, remaining_work: 4, percent_complete: 100)
#     .to have_correctable_remaining_work_value
#   # good values
#   expect(work: 10, remaining_work: 5, percent_complete: 50)
#     .not_to have_correctable_remaining_work_value
#   # % complete is the one to be corrected, not remaining work
#   expect(work: 10, remaining_work: 5, percent_complete: 12)
#     .not_to have_correctable_remaining_work_value
RSpec::Matchers.define :have_correctable_remaining_work_value do
  match do |progress_values|
    @work, @remaining_work, @percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    # Create a dummy class to access the ProgressValuesCalculations module
    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }

    dummy_class.correctable_remaining_work_value?(
      work: @work,
      remaining_work: @remaining_work,
      percent_complete: @percent_complete
    )
  end

  failure_message do
    <<~MESSAGE
      expected remaining work to be correctable:
        work: #{@work ? "#{@work}h" : '-'}
        remaining_work: #{@remaining_work ? "#{@remaining_work}h" : '-'}
        percent_complete: #{@percent_complete ? "#{@percent_complete}%" : '-'}
    MESSAGE
  end

  failure_message_when_negated do
    <<~MESSAGE
      expected remaining work to not be correctable:
        work: #{@work ? "#{@work}h" : '-'}
        remaining_work: #{@remaining_work ? "#{@remaining_work}h" : '-'}
        percent_complete: #{@percent_complete ? "#{@percent_complete}%" : '-'}
    MESSAGE
  end

  description do
    "have correctable remaining work value"
  end
end

# Custom matcher to check if % complete value can be corrected because it is
# inconsistent with work and remaining work as returned by
# WorkPackages::SetAttributesService::ProgressValuesCalculations#correctable_percent_complete_value?
#
# The helper helps at outputting the acceptable range of values for the percent
# complete and/or remaining work when it fails.
#
# Usage:
#   expect(work: 10, remaining_work: 0, percent_complete: 0).to have_correctable_percent_complete_value
#   expect(work: 10, remaining_work: 5, percent_complete: 42).to have_correctable_percent_complete_value
#   expect(work: 10, remaining_work: 0, percent_complete: 100).not_to have_correctable_percent_complete_value
#   expect(work: 10, remaining_work: 5, percent_complete: 50).not_to have_correctable_percent_complete_value
RSpec::Matchers.define :have_correctable_percent_complete_value do
  match do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    # Create a dummy class to access the ProgressValuesCalculations module
    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }

    dummy_class.correctable_percent_complete_value?(work:, remaining_work:, percent_complete:)
  end

  failure_message do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }
    calculation_applicable = dummy_class.percent_complete_calculation_applicable?(work:, remaining_work:, percent_complete:)
    explanation =
      if calculation_applicable
        expected_percent_complete = dummy_class.calculate_percent_complete(work:, remaining_work:)
        expected_remaining_work = dummy_class.calculate_remaining_work(work:, percent_complete:)

        calculated_percent_complete_explanation =
          "calculated percent_complete is #{expected_percent_complete}% when work=#{work}h and remaining_work=#{remaining_work}h"
        calculated_remaining_work_explanation =
          "calculated remaining_work is #{expected_remaining_work}h when work=#{work}h and percent_complete=#{percent_complete}%"

        if expected_percent_complete == percent_complete
          correct_derived_explanation = calculated_percent_complete_explanation
          other_derived_explanation = calculated_remaining_work_explanation
        else
          correct_derived_explanation = calculated_remaining_work_explanation
          other_derived_explanation = calculated_percent_complete_explanation
        end

        <<~EXPLANATION
          but it is already correct:
            #{correct_derived_explanation}
            (and FYI, #{other_derived_explanation})
        EXPLANATION
      else
        "but % complete cannot be calculated with these progress values"
      end

    <<~MESSAGE
      expected percent complete to be correctable:
        work: #{work ? "#{work}h" : '-'}
        remaining_work: #{remaining_work ? "#{remaining_work}h" : '-'}
        percent_complete: #{percent_complete ? "#{percent_complete}%" : '-'}

      #{explanation}
    MESSAGE
  end

  failure_message_when_negated do |progress_values|
    work, remaining_work, percent_complete = progress_values.values_at(:work, :remaining_work, :percent_complete)

    dummy_class = Class.new { extend WorkPackages::SetAttributesService::ProgressValuesCalculations }
    expected_percent_complete = dummy_class.calculate_percent_complete(work:, remaining_work:)
    expected_remaining_work = dummy_class.calculate_remaining_work(work:, percent_complete:)

    <<~MESSAGE
      expected percent complete to not be correctable:
        work: #{work ? "#{work}h" : '-'}
        remaining_work: #{remaining_work ? "#{remaining_work}h" : '-'}
        percent_complete: #{percent_complete ? "#{percent_complete}%" : '-'}

      but % complete can be calculated, and it is not correct:
        either percent_complete should be #{expected_percent_complete}% when work=#{work}h and remaining_work=#{remaining_work}h
        or remaining_work should be #{expected_remaining_work}h when work=#{work}h and percent_complete=#{percent_complete}%
    MESSAGE
  end

  description do
    "have correctable percent complete value"
  end
end
