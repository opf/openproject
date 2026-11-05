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

module TimeEntries
  class AdjustRemainingWorkService
    attr_reader :user, :time_entry, :previous_reduction

    delegate :entity, to: :time_entry

    def initialize(user:, time_entry:)
      @user = user
      @time_entry = time_entry
      @previous_reduction = time_entry.remaining_work_reduction_in_minutes
    end

    def call
      if time_entry.destroyed?
        restore(entity)
      elsif time_entry.previously_new_record?
        reduce(entity, restored_minutes: 0)
      else
        readjust
      end
    end

    private

    def readjust
      return ServiceResult.success if previous_reduction.nil?
      return move if previous_entity != entity

      reduce(entity, restored_minutes: previous_reduction)
    end

    def move
      restored = restore(previous_entity)
      return restored if restored.failure?

      reduce(entity, restored_minutes: 0)
    end

    def restore(work_package)
      return ServiceResult.success unless adjustable?(work_package) && previous_reduction&.positive?

      work_package.lock!
      return ServiceResult.success if work_package.remaining_hours.nil?

      update_remaining_work(work_package, available_minutes(work_package, previous_reduction))
    end

    def reduce(work_package, restored_minutes:)
      return store_reduction(nil) unless adjustable?(work_package)

      work_package.lock!
      return store_reduction(0) if work_package.remaining_hours.nil?

      available = available_minutes(work_package, restored_minutes)
      reduction = [logged_minutes, available].min

      store_reduction(reduction)
      update_remaining_work(work_package, available - reduction)
    end

    def available_minutes(work_package, restored_minutes)
      capped_at_work(work_package, minutes(work_package.remaining_hours) + restored_minutes)
    end

    def logged_minutes
      minutes(time_entry.hours)
    end

    def adjustable?(work_package)
      work_package.is_a?(WorkPackage) &&
        WorkPackage.work_based_mode? &&
        work_package.project.logged_time_reduces_remaining_work?
    end

    def previous_entity
      return entity unless time_entry.saved_change_to_entity_id? || time_entry.saved_change_to_entity_type?
      return unless time_entry.entity_type_before_last_save == "WorkPackage"

      WorkPackage.find_by(id: time_entry.entity_id_before_last_save)
    end

    def capped_at_work(work_package, remaining_minutes)
      return remaining_minutes if work_package.estimated_hours.nil?

      [remaining_minutes, minutes(work_package.estimated_hours)].min
    end

    def store_reduction(reduction)
      time_entry.update_column(:remaining_work_reduction_in_minutes, reduction) unless previous_reduction == reduction

      ServiceResult.success
    end

    def update_remaining_work(work_package, remaining_minutes)
      return ServiceResult.success if remaining_minutes == minutes(work_package.remaining_hours)

      WorkPackages::UpdateService
        .new(user:, model: work_package, contract_class: EmptyContract)
        .call(remaining_hours: remaining_minutes / 60.0, journal_cause: Journal::CausedByLoggedTime.new)
    end

    def minutes(hours)
      (hours.to_f * 60).round
    end
  end
end
