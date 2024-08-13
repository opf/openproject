#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class WorkPackages::SetAttributesService
  class DeriveProgressValuesWorkBased < DeriveProgressValuesBase
    private

    def derive_progress_attributes
      raise ArgumentError, "Cannot use #{self.class.name} in status-based mode" if WorkPackage.status_based_mode?

      # do not change anything if some values are invalid: this will be detected
      # by the contract and errors will be set.
      return if invalid_progress_values?

      update_work if derive_work?
      update_remaining_work if derive_remaining_work?
      update_percent_complete if derive_percent_complete?
    end

    def invalid_progress_values?
      work&.negative? \
        || remaining_work&.negative? \
        || percent_complete_out_of_range? \
        || percent_complete_unparsable? \
        || remaining_work_set_greater_than_work?
    end

    def percent_complete_out_of_range?
      percent_complete && !percent_complete.between?(0, 100)
    end

    def derive_work?
      work_not_provided_by_user? && (remaining_work_changed? || percent_complete_changed?)
    end

    def derive_remaining_work?
      remaining_work_not_provided_by_user? && (work_changed? || percent_complete_changed?)
    end

    def derive_percent_complete?
      percent_complete_not_provided_by_user? && (work_changed? || remaining_work_changed?)
    end

    def update_work
      return if work_set_and_no_user_inputs_provided_for_both_remaining_work_and_percent_complete?
      return if remaining_work_unset? && percent_complete_unset?
      return if percent_complete == 100 # would be Infinity if computed when % complete is 100%

      if remaining_work_unset?
        work_package.derived_progress_hints[:done_ratio] = "unset because remaining work is unset"
        self.work = nil
      else
        work_package.derived_progress_hints[:done_ratio] = "derived from % complete and remaining work"
        self.work = work_from_percent_complete_and_remaining_work
      end
    end

    # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    def update_remaining_work
      return if work_unset? && percent_complete_unset?
      return if work_was_unset? && remaining_work_set? # remaining work is kept and % complete will be set

      if work_set? && remaining_work_unset? && percent_complete_unset?
        work_package.derived_progress_hints[:remaining_hours] = "set to same value as work"
        self.remaining_work = work
      elsif work_changed? && work_set? && remaining_work_set? && !percent_complete_changed?
        delta = work - work_was
        if delta.positive?
          work_package.derived_progress_hints[:remaining_hours] = "increased by same amout as work"
        elsif delta.negative?
          work_package.derived_progress_hints[:remaining_hours] = "decreased by same amout as work"
        end
        self.remaining_work = (remaining_work + delta).clamp(0.0, work)
      elsif work_unset?
        work_package.derived_progress_hints[:remaining_hours] = "unset because work is unset and % complete is set"
        self.remaining_work = nil
      elsif percent_complete_unset?
        work_package.derived_progress_hints[:remaining_hours] = "unset because % complete is unset and work is set"
        self.remaining_work = nil
      else
        work_package.derived_progress_hints[:remaining_hours] = "derived from work and % complete"
        self.remaining_work = remaining_work_from_percent_complete_and_work
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/PerceivedComplexity

    def update_percent_complete
      return if work_unset?

      if work.zero?
        work_package.derived_progress_hints[:done_ratio] = "derived from work and remaining work"
        self.percent_complete = nil
      elsif remaining_work_unset?
        work_package.derived_progress_hints[:done_ratio] = "unset because remaining work is unset"
        self.percent_complete = nil
      else
        work_package.derived_progress_hints[:done_ratio] = "derived from work and remaining work"
        self.percent_complete = percent_complete_from_work_and_remaining_work
      end
    end

    def percent_complete_from_work_and_remaining_work
      completed_work = work - remaining_work
      completion_ratio = completed_work.to_f / work

      (completion_ratio * 100).round
    end

    def work_from_percent_complete_and_remaining_work
      remaining_percent_complete = 1.0 - ((percent_complete || 0) / 100.0)
      remaining_work / remaining_percent_complete
    end

    def percent_complete_unparsable?
      !PercentageConverter.valid?(work_package.done_ratio_before_type_cast)
    end

    def remaining_work_set_greater_than_work?
      attributes_from_user == %i[remaining_work] && work && remaining_work && remaining_work > work
    end

    def attributes_from_user
      @attributes_from_user ||= PROGRESS_ATTRIBUTES.filter { |attr| public_send(:"#{attr}_came_from_user?") }
    end

    def work_set_and_no_user_inputs_provided_for_both_remaining_work_and_percent_complete?
      work_set? && (remaining_work_not_provided_by_user? || percent_complete_not_provided_by_user?)
    end
  end
end
