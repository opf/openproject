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

module TimeEntries
  class BaseContract < ::ModelContract
    include AssignableValuesContract
    include AssignableCustomFieldValues
    include PastMonthRestriction

    delegate :entity,
             :project,
             :available_custom_fields,
             :new_record?,
             to: :model

    def self.model
      TimeEntry
    end

    validate :validate_hours_are_in_range
    validate :validate_spent_on_is_working_day
    validate :validate_project_is_set
    validate :validate_entity
    validate :validate_user

    validates :spent_on,
              date: { before_or_equal_to: Proc.new { Date.new(9999, 12, 31) },
                      allow_blank: true },
              unless: Proc.new { spent_on.blank? }

    attribute :project_id
    attribute :entity_id
    attribute :entity_type
    attribute :activity_id do
      validate_activity_active
    end
    attribute :ongoing do
      validate_self_timer
      validate_no_other_ongoing
    end
    attribute :hours
    attribute :comments
    attribute_alias :comments, :comment

    attribute :spent_on
    attribute :tyear
    attribute :tmonth
    attribute :tweek
    attribute :user_id,
              permission: :log_time

    attribute :start_time # TODO: Add validation with global setting

    def assignable_activities
      if model.project
        TimeEntryActivity.active_in_project(model.project)
      else
        TimeEntryActivity.none
      end
    end

    # Necessary for custom fields of type version.
    def assignable_versions(only_open: true)
      entity.try(:assignable_versions, only_open:) || project.try(:assignable_versions, only_open:) || []
    end

    private

    def validate_entity
      return if model.entity.nil?

      errors.add :entity, :invalid if entity_invisible? || entity_not_in_project?
    end

    def validate_user
      return unless model.user || model.user_id_changed?
      return if model.user == model.logged_by

      if user_invisible?
        errors.add :user_id, :invalid
      end
    end

    def validate_hours_are_in_range
      return errors.add(:hours, :invalid) if model.hours&.negative?

      validate_hours_within_max_per_entry
      validate_hours_within_max_per_day
      validate_hours_within_user_working_hours
    end

    def validate_hours_within_max_per_entry
      limit = TimeEntry.max_hours_per_entry
      return if limit.nil? || model.hours.nil? || model.hours <= limit

      errors.add :hours, :max_hours_per_entry_exceeded, limit:
    end

    def validate_hours_within_max_per_day
      limit = TimeEntry.max_hours_per_day
      return if limit.nil? || !day_total_determinable?
      return if hours_already_logged_on_day + model.hours <= limit

      errors.add :hours, :max_hours_per_day_exceeded, limit:
    end

    def day_total_determinable?
      model.hours.present? && model.spent_on.present? && model.user.present?
    end

    def hours_already_logged_on_day
      TimeEntry.of_user_and_day(model.user, model.spent_on, excluding: model).sum(:hours)
    end

    # Compared in whole minutes, since that is the granularity time is logged in and how the
    # schedule stores its hours. Users without a working hours schedule are not restricted at
    # all, so that enabling the setting does not block logging on instances that defined none.
    def validate_hours_within_user_working_hours
      return unless TimeEntry.limit_to_user_working_hours?
      return unless day_total_determinable?

      capacity = user_capacity_in_minutes_on(model.spent_on)
      return if capacity.nil?
      return if in_minutes(hours_already_logged_on_day + model.hours) <= capacity

      errors.add :hours, :exceeds_user_working_hours, limit: format_hours(capacity / 60.0)
    end

    def user_capacity_in_minutes_on(date)
      model.user.working_hours.valid_for_date(date)&.effective_minutes_on(date)
    end

    def in_minutes(hours)
      (hours * 60).round
    end

    def format_hours(hours)
      ActiveSupport::NumberHelper.number_to_rounded(hours, precision: 2, strip_insignificant_zeros: true)
    end

    def validate_spent_on_is_working_day
      return unless TimeEntry.prohibit_logging_on_non_working_days?
      return if model.spent_on.nil? || model.user.nil?
      return unless globally_non_working?(model.spent_on) || personally_non_working?(model.spent_on)

      errors.add :spent_on, :not_a_working_day
    end

    def globally_non_working?(date)
      WorkPackages::Shared::WorkingDays.new.non_working?(date)
    end

    def personally_non_working?(date)
      model.user.non_working_times.overlapping(date..date).exists?
    end

    def validate_project_is_set
      errors.add :project_id, :invalid if model.project.nil?
    end

    def validate_activity_active
      errors.add :activity_id, :inclusion if model.activity_id && !assignable_activities.exists?(model.activity_id)
    end

    def entity_invisible?
      model.entity.nil? || !model.entity.visible?(user)
    end

    def entity_not_in_project?
      model.entity && model.project != model.entity.project
    end

    def user_invisible?
      model.user.nil? || !model.user.visible?
    end

    def validate_self_timer
      errors.add :ongoing, :not_current_user if model.ongoing? && model.user != user
    end

    def validate_no_other_ongoing
      if model.ongoing? && model.ongoing_changed? && TimeEntry.ongoing_for_user_other_than(model.user, model).any?
        errors.add :base,
                   :duplicate_ongoing
      end
    end
  end
end
