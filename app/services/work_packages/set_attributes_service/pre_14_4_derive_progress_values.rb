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

# rubocop:disable Metrics/AbcSize
class WorkPackages::SetAttributesService
  class Pre144DeriveProgressValues
    attr_reader :work_package

    def initialize(work_package)
      @work_package = work_package
    end

    def call
      update_progress_attributes
    end

    # From this point, copied over from 109b135b:app/services/work_packages/set_attributes_service.rb#L287-L427
    def update_progress_attributes
      if WorkPackage.use_status_for_done_ratio?
        update_done_ratio
        update_remaining_hours
      elsif only_percent_complete_initially_set?
        update_remaining_hours_from_percent_complete
      else
        update_estimated_hours
        update_remaining_hours
        update_done_ratio
      end
      round_progress_values
    end

    def only_percent_complete_initially_set?
      return false if work_package.done_ratio.nil?
      return false if work_package.remaining_hours.present?

      work_package.estimated_hours_changed? && work_package.estimated_hours.present?
    end

    def work_was_unset_and_remaining_work_is_set?
      work_package.estimated_hours_was.nil? && work_package.remaining_hours.present?
    end

    # Compute and update +done_ratio+ if its dependent attributes are being modified.
    # The dependent attributes for +done_ratio+ are
    # - +remaining_hours+
    # - +estimated_hours+
    #
    # Unless both +remaining_hours+ and +estimated_hours+ are set, +done_ratio+ will be
    # considered nil.
    def update_done_ratio
      if WorkPackage.use_status_for_done_ratio?
        return unless work_package.status_id_changed?

        work_package.done_ratio = work_package.status.default_done_ratio
      else
        return unless work_package.remaining_hours_changed? || work_package.estimated_hours_changed?

        work_package.done_ratio = if done_ratio_dependent_attribute_unset?
                                    nil
                                  else
                                    compute_done_ratio
                                  end
      end
    end

    def round_progress_values
      rounded = work_package.estimated_hours&.round(2)
      if rounded != work_package.estimated_hours
        work_package.estimated_hours = rounded
      end
      rounded = work_package.remaining_hours&.round(2)
      if rounded != work_package.remaining_hours
        work_package.remaining_hours = rounded
      end
    end

    def update_remaining_hours_from_percent_complete
      return if work_package.remaining_hours_came_from_user?
      return if work_package.estimated_hours&.negative?

      work_package.remaining_hours = remaining_hours_from_done_ratio_and_estimated_hours
    end

    def done_ratio_dependent_attribute_unset?
      work_package.remaining_hours.nil? || work_package.estimated_hours.nil?
    end

    def compute_done_ratio
      # do not change done ratio if the values are invalid
      if invalid_progress_values?
        return work_package.done_ratio
      end

      completed_work = work_package.estimated_hours - work_package.remaining_hours
      completion_ratio = completed_work.to_f / work_package.estimated_hours

      (completion_ratio * 100).round(2)
    end

    def invalid_progress_values?
      work = work_package.estimated_hours
      remaining_work = work_package.remaining_hours

      return true if work.negative?
      return true if remaining_work.negative?

      work && remaining_work && remaining_work > work
    end

    def update_estimated_hours
      return unless WorkPackage.use_field_for_done_ratio?
      return if work_package.estimated_hours_came_from_user?
      return unless work_package.remaining_hours_changed?

      work = work_package.estimated_hours
      remaining_work = work_package.remaining_hours
      return if work.present?
      return if remaining_work.nil? || remaining_work.negative?

      work_package.estimated_hours = estimated_hours_from_done_ratio_and_remaining_hours
    end

    # When in "Status-based" mode for % Complete, remaining hours are based
    # on the computation of it derived from the status's default done ratio
    # and the estimated hours. If the estimated hours are unset, then also
    # unset the remaining hours.
    # rubocop:disable Metrics/PerceivedComplexity
    def update_remaining_hours
      if WorkPackage.use_status_for_done_ratio?
        update_remaining_hours_from_percent_complete
      elsif WorkPackage.use_field_for_done_ratio? &&
        work_package.estimated_hours_changed?
        return if work_package.remaining_hours_came_from_user?
        return if work_package.estimated_hours&.negative?
        return if work_was_unset_and_remaining_work_is_set? # remaining work is kept and % complete will be set

        if work_package.estimated_hours.nil? || work_package.remaining_hours.nil?
          work_package.remaining_hours = work_package.estimated_hours
        else
          delta = work_package.estimated_hours - work_package.estimated_hours_was
          work_package.remaining_hours = (work_package.remaining_hours + delta).clamp(0.0, work_package.estimated_hours)
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def estimated_hours_from_done_ratio_and_remaining_hours
      remaining_ratio = 1.0 - ((work_package.done_ratio || 0) / 100.0)
      work_package.remaining_hours / remaining_ratio
    end

    def remaining_hours_from_done_ratio_and_estimated_hours
      return nil if work_package.done_ratio.nil? || work_package.estimated_hours.nil?

      completed_work = work_package.estimated_hours * work_package.done_ratio / 100.0
      remaining_hours = (work_package.estimated_hours - completed_work).round(2)
      remaining_hours.clamp(0.0, work_package.estimated_hours)
    end
  end
end
# rubocop:enable Metrics/AbcSize
