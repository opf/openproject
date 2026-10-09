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

module Reminders
  class BaseContract < ::ModelContract
    MAX_NOTE_CHARS_LENGTH = 128

    attribute :creator_id
    attribute :remindable_id
    attribute :remindable_type
    attribute :remind_at
    attribute :note

    validate :validate_creator_exists
    validate :validate_acting_user
    validate :validate_remindable_exists
    validate :validate_manage_reminders_permissions
    validate :validate_remind_at_present
    validate :validate_remind_at_is_in_future
    validate :validate_note_length

    def self.model = Reminder

    private

    def validate_creator_exists
      errors.add :creator, :not_found unless User.exists?(model.creator_id)
    end

    def validate_acting_user
      errors.add :creator, :invalid unless model.creator_id == user.id
    end

    def validate_remindable_exists
      errors.add :remindable, :not_found if model.remindable.blank?
    end

    def validate_remind_at_present
      errors.add :remind_at, :blank if model.remind_at.blank?
    end

    def validate_remind_at_is_in_future
      if model.remind_at.present? && model.remind_at < Time.current
        errors.add :remind_at, :datetime_must_be_in_future
      end
    end

    def validate_note_length
      if model.note.present? && model.note.length > MAX_NOTE_CHARS_LENGTH
        errors.add :note, :too_long, count: MAX_NOTE_CHARS_LENGTH
      end
    end

    def validate_manage_reminders_permissions
      return if errors.added?(:remindable, :not_found)

      unless can_manage_reminders?
        errors.add :base, :error_unauthorized
      end
    end

    def can_manage_reminders?
      user.logged? && user.allowed_in_project?(:view_work_packages, model.remindable.project)
    end
  end
end
