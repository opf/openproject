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

module MeetingOutcomes
  module EditableItem
    extend ActiveSupport::Concern

    included do
      validate :validate_editable, :validate_meeting_existence, :user_allowed_to_add
      validate :validate_not_in_backlog
    end

    protected

    def validate_editable
      return unless visible?

      unless model.editable?
        errors.add :base, I18n.t(:text_outcome_not_editable_anymore)
      end
    end

    def validate_meeting_existence
      return if model.meeting_agenda_item.meeting.nil?

      unless visible?
        errors.add :base, :does_not_exist
      end
    end

    def user_allowed_to_add
      return unless visible?

      unless user.allowed_in_project?(:manage_outcomes, model.meeting_agenda_item.project)
        errors.add :base, :error_unauthorized
      end
    end

    def validate_not_in_backlog
      if model.meeting_agenda_item.in_backlog?
        errors.add :base, I18n.t(:text_outcome_not_editable_anymore)
      end
    end

    private

    def visible?
      @visible ||= model.meeting_agenda_item.meeting&.visible?(user)
    end
  end
end
