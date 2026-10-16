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

module MeetingAgendaItems
  module Concerns
    module CopyAttachments
      private

      def copy_attachments_from_meeting(agenda_item, source_meeting_id)
        return if agenda_item.notes.blank?
        return if agenda_item.meeting_id == source_meeting_id

        source_meeting = Meeting.find(source_meeting_id)
        source_meeting.attachments.each do |attachment|
          next unless agenda_item.notes.include?("/attachments/#{attachment.id}/")

          copy_attachment(attachment, agenda_item.meeting, agenda_item)
        end
      end

      def copy_attachment(source_attachment, target_meeting, agenda_item)
        copy = Attachment.new(
          source_attachment
            .dup
            .attributes
            .except("file")
            .merge("author_id" => user.id, "container_id" => target_meeting.id)
        )

        source_attachment.file.copy_to(copy)
        copy.save!

        updated_notes = agenda_item.notes.gsub(
          "/api/v3/attachments/#{source_attachment.id}/content",
          "/api/v3/attachments/#{copy.id}/content"
        )

        agenda_item.update!(notes: updated_notes)
      end
    end
  end
end
