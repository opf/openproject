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

module MeetingAgendaItems
  class UpdateContract < BaseContract
    validate :user_allowed_to_edit_in_source_project
    validate :user_allowed_to_edit_in_destination_project
    validate :section_belongs_to_meeting

    attribute :lock_version do
      if model.lock_version.nil? || model.lock_version_changed?
        errors.add :base, :error_conflict
      end
    end

    ##
    # Meeting agenda items can currently be only edited
    # through the project permission :manage_agendas
    # When MeetingRole becomes available, agenda items will
    # be edited through meeting permissions :manage_agendas
    def user_allowed_to_edit_in_source_project
      unless user.allowed_in_project?(:manage_agendas, source_meeting.project)
        errors.add :base, :error_unauthorized
      end
    end

    def user_allowed_to_edit_in_destination_project
      return unless model.meeting_id_changed?

      unless user.allowed_in_project?(:manage_agendas, model.project)
        errors.add :base, :error_unauthorized
      end
    end

    def section_belongs_to_meeting
      return unless model.meeting_section_id_changed?

      item_meeting = model.meeting
      section_meeting = model.meeting_section.meeting

      return if item_meeting == section_meeting

      # For recurring meetings, allow moves across meetings in the same series
      if item_meeting.recurring? &&
        item_meeting.recurring_meeting_id == section_meeting.recurring_meeting_id
        return
      end

      errors.add :meeting_section, :invalid
    end

    private

    def source_meeting
      return model.meeting unless model.meeting_id_changed?

      Meeting.find(model.meeting_id_was)
    end
  end
end
