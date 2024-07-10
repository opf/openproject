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

      if only_percent_complete_initially_set?
        update_remaining_work_from_percent_complete
      else
        update_work
        update_remaining_work
        update_percent_complete
      end
    end

    def only_percent_complete_initially_set?
      return false if percent_complete_unset?
      return false if remaining_work_set?

      work_changed? && work.present?
    end

    # Compute and update +percent_complete+ if its dependent attributes are being modified.
    # The dependent attributes for +percent_complete+ are
    # - +work+
    # - +remaining_work+
    #
    # Unless both +remaining_work+ and +work+ are set, +percent_complete+ will be
    # considered nil.
    def update_percent_complete
      return unless remaining_work_changed? || work_changed?
      return if work_unset?

      self.percent_complete = if remaining_work_unset?
                                nil
                              else
                                compute_percent_complete
                              end
    end

    def update_remaining_work_from_percent_complete
      return if remaining_work_came_from_user?
      return if work&.negative?

      self.remaining_work = remaining_work_from_percent_complete_and_work
    end

    def compute_percent_complete
      # do not change % complete if the progress values are invalid
      return percent_complete if invalid_progress_values?
      return nil if work.zero?

      completed_work = work - remaining_work
      completion_ratio = completed_work.to_f / work

      (completion_ratio * 100).round
    end

    def invalid_progress_values?
      return true if work.negative?
      return true if remaining_work.negative?

      work && remaining_work && remaining_work > work
    end

    def update_work
      return if work_came_from_user?
      return unless remaining_work_changed? || percent_complete_changed?

      return if work.present? && !(remaining_work_changed? && percent_complete_changed?)
      return if remaining_work_unset? || remaining_work.negative?

      self.work = work_from_percent_complete_and_remaining_work
    end

    # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity
    def update_remaining_work
      return unless work_changed? || percent_complete_changed?
      return if remaining_work_came_from_user?
      return if work&.negative?
      return if work_unset? && percent_complete_unset?
      return if work_was_unset? && remaining_work_set? # remaining work is kept and % complete will be set

      if work_set? && remaining_work_unset? && percent_complete_unset?
        self.remaining_work = work
      elsif work_unset? || percent_complete_unset?
        self.remaining_work = nil
      elsif work_changed? && !percent_complete_changed?
        delta = work - work_was
        self.remaining_work = (remaining_work + delta).clamp(0.0, work)
      else
        self.remaining_work = remaining_work_from_percent_complete_and_work
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/PerceivedComplexity

    def work_from_percent_complete_and_remaining_work
      remaining_percent_complete = 1.0 - ((percent_complete || 0) / 100.0)
      remaining_work / remaining_percent_complete
    end
  end
end
