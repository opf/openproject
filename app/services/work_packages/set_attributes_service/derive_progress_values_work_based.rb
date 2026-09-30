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
  class DeriveProgressValuesWorkBased < DeriveProgressValuesBase
    private

    attr_accessor :skip_percent_complete_derivation

    def derive_progress_attributes
      raise ArgumentError, "Cannot use #{self.class.name} in status-based mode" if WorkPackage.status_based_mode?

      # do not change anything if some values are invalid: this will be detected
      # by the contract and errors will be set.
      return if invalid_progress_values?

      set_complete if set_complete_for_closed_status?
      update_work if derive_work?
      update_remaining_work if derive_remaining_work?
      update_percent_complete if derive_percent_complete?
    end

    def invalid_progress_values?
      work_invalid? \
        || remaining_work_invalid? \
        || percent_complete_out_of_range? \
        || percent_complete_unparsable? \
        || remaining_work_set_greater_than_work?
    end

    def percent_complete_out_of_range?
      percent_complete && !percent_complete.between?(0, 100)
    end

    def set_complete_for_closed_status?
      WorkPackage.complete_on_status_closed? \
        && percent_complete_not_provided_by_user? \
        && work_package.status_id_changed? \
        && work_package.closed?
    end

    def derive_work?
      work_not_provided_by_user? && (remaining_work_changed? || percent_complete_changed?)
    end

    def derive_remaining_work?
      (remaining_work_not_provided_by_user? && (work_changed? || percent_complete_changed?)) \
        || fixable_remaining_work?
    end

    def derive_percent_complete?
      return false if skip_percent_complete_derivation

      (percent_complete_not_provided_by_user? && (work_changed? || remaining_work_changed?)) \
        || fixable_percent_complete?
    end

    def set_complete
      self.percent_complete = 100
      skip_percent_complete_derivation!
    end

    # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    def update_work
      return if remaining_work_empty? && percent_complete_empty?
      return if percent_complete == 100 # would be Infinity if computed when % complete is 100%
      return unless work_can_be_derived?

      if remaining_work_empty?
        return unless remaining_work_changed?

        set_hint(:estimated_hours, :cleared_because_remaining_work_is_empty)
        self.work = nil
      elsif percent_complete_empty?
        set_hint(:estimated_hours, :same_as_remaining_work)
        self.work = remaining_work
      else
        set_hint(:estimated_hours, :derived)
        self.work = calculate_work(remaining_work:, percent_complete:)
        skip_percent_complete_derivation!
      end
    end

    def update_remaining_work
      return if work_empty? && percent_complete_empty?
      return if work_was_empty? && remaining_work_set? # remaining work is kept and % complete will be unset

      if work_set? && remaining_work_empty? && percent_complete_empty?
        set_hint(:remaining_hours, :same_as_work)
        self.remaining_work = work
      elsif work_changed? && work_set? && remaining_work_set? && percent_complete_not_provided_by_user?
        delta = work - work_was
        if delta.positive?
          set_hint(:remaining_hours, :increased_by_delta_like_work, delta:)
        elsif delta.negative?
          set_hint(:remaining_hours, :decreased_by_delta_like_work, delta:)
        end
        self.remaining_work = (remaining_work + delta).clamp(0.0, work)
      elsif work_empty?
        return unless work_changed?

        set_hint(:remaining_hours, :cleared_because_work_is_empty)
        self.remaining_work = nil
      elsif percent_complete_empty?
        set_hint(:remaining_hours, :cleared_because_percent_complete_is_empty)
        self.remaining_work = nil
      else
        set_hint(:remaining_hours, :derived)
        self.remaining_work = calculate_remaining_work(work:, percent_complete:)
        skip_percent_complete_derivation!
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/PerceivedComplexity

    def update_percent_complete
      return if work_empty?

      if work < 0.005
        set_hint(:done_ratio, :cleared_because_work_is_0h)
        self.percent_complete = nil
      elsif remaining_work_empty?
        set_hint(:done_ratio, :cleared_because_remaining_work_is_empty)
        self.percent_complete = nil
      else
        set_hint(:done_ratio, :derived)
        self.percent_complete = calculate_percent_complete(work:, remaining_work:)
      end
    end

    def skip_percent_complete_derivation!
      self.skip_percent_complete_derivation = true
    end

    def percent_complete_unparsable?
      !PercentageConverter.valid?(work_package.done_ratio_before_type_cast)
    end

    def remaining_work_set_greater_than_work?
      (work_was_empty? || remaining_work_came_from_user?) \
        && percent_complete_not_provided_by_user? \
        && work && remaining_work && remaining_work > work
    end

    def work_can_be_derived?
      work_empty? \
        || (remaining_work_came_from_user? && percent_complete_came_from_user?) \
        || (remaining_work_empty? && remaining_work_came_from_user?)
    end

    def fixable_remaining_work?
      no_progress_value_provided_by_user? \
        && correctable_remaining_work_value?(work:, remaining_work:, percent_complete:)
    end

    def fixable_percent_complete?
      no_progress_value_provided_by_user? \
        && correctable_percent_complete_value?(work:, remaining_work:, percent_complete:)
    end

    def no_progress_value_provided_by_user?
      work_not_provided_by_user? \
        && remaining_work_not_provided_by_user? \
        && percent_complete_not_provided_by_user?
    end
  end
end
