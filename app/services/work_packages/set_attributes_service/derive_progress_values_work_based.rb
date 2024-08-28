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

class WorkPackages::SetAttributesService
  class DeriveProgressValuesWorkBased < DeriveProgressValuesBase
    private

    attr_accessor :skip_percent_complete_derivation

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
      work_invalid? \
        || remaining_work_invalid? \
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
      percent_complete_not_provided_by_user? && (work_changed? || remaining_work_changed?) \
        && !skip_percent_complete_derivation
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
        self.work = work_from_percent_complete_and_remaining_work
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
          set_hint(:remaining_hours, :increased_like_work)
        elsif delta.negative?
          set_hint(:remaining_hours, :decreased_like_work)
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
        self.remaining_work = remaining_work_from_percent_complete_and_work
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
        self.percent_complete = percent_complete_from_work_and_remaining_work
      end
    end

    def skip_percent_complete_derivation!
      self.skip_percent_complete_derivation = true
    end

    def percent_complete_from_work_and_remaining_work
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

    def work_from_percent_complete_and_remaining_work
      remaining_percent_complete = 1.0 - (percent_complete / 100.0)
      remaining_work / remaining_percent_complete
    end

    def work_invalid?
      !work_valid?
    end

    def remaining_work_invalid?
      !remaining_work_valid?
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
  end
end
