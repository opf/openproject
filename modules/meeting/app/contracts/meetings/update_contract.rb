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

module Meetings
  class UpdateContract < BaseContract
    include Redmine::I18n
    include UnchangedProject

    validate :user_allowed_to_edit_in_source_project
    validate :user_allowed_to_edit_in_destination_project
    validate :meeting_is_editable
    validate :valid_rescheduling_date, if: -> { check_reschedule? }

    attribute :lock_version do
      if model.lock_version.nil? || model.lock_version_changed?
        errors.add :base, :error_conflict
      end
    end

    def user_allowed_to_edit_in_source_project
      with_unchanged_project_id do
        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:edit_meetings, model.project)
      end
    end

    def user_allowed_to_edit_in_destination_project
      return unless model.project_id_changed?

      unless user.allowed_in_project?(:edit_meetings, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    def meeting_is_editable
      return unless user.allowed_in_project?(:edit_meetings, model.project)

      # A closed meeting may still be reopened or otherwise have its state changed
      #  but no other attribute of it may be edited
      return unless model.state_was == "closed"
      return if only_state_changed?

      errors.add :base, I18n.t(:text_meeting_not_editable_anymore)
    end

    def only_state_changed?
      model.changed == %w[state]
    end

    def valid_rescheduling_date # rubocop:disable Metrics/AbcSize
      if model.start_time < Time.zone.now
        errors.add :start_date, :after_today
        return
      end

      check_before(model.recurring_meeting.next_occurrence(from_time: model.recurrence_start_time))
      check_after(model.recurring_meeting.previous_occurrence(from_time: model.recurrence_start_time))
      check_after(model.recurring_meeting.first_occurrence)
    end

    def check_before(time)
      # Avoid adding more errors if we already checked closer candidates
      return if errors.has_key?(:start_date)

      if time && model.start_time >= time
        errors.add :start_date, :before, date: format_time(time)
      end
    end

    def check_after(time)
      # Avoid adding more errors if we already checked closer candidates
      return if errors.has_key?(:start_date)

      if time && model.start_time <= time
        errors.add :start_date, :after, date: format_time(time)
      end
    end

    def check_reschedule?
      model.recurring_meeting_id &&
        model.recurrence_start_time.present? &&
        model.changed.intersect?(%w[start_time start_date start_time_hour])
    end
  end
end
