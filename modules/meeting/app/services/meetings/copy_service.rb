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
  class CopyService
    include ::Shared::ServiceContext
    include ::Contracted
    include ::Copy::Concerns::CopyAttachments

    attr_accessor :user,
                  :meeting,
                  :contract_class

    def initialize(user:, model:, contract_class: Meetings::CreateContract)
      self.user = user
      self.meeting = model
      self.contract_class = contract_class
    end

    def call(send_notifications: nil, save: true, copy_agenda: true, copy_attachments: false, attributes: {})
      if save
        create(meeting, attributes, send_notifications:, copy_agenda:, copy_attachments:)
      else
        build(meeting, attributes)
      end
    end

    protected

    def create(meeting, attribute_overrides, send_notifications:, copy_agenda:, copy_attachments:)
      Meetings::CreateService
        .new(user:, contract_class:)
        .call(**copied_attributes(meeting, attribute_overrides).merge(send_notifications:).symbolize_keys)
        .on_success do |call|
        copy_meeting_agenda(call.result) if copy_agenda
        copy_meeting_attachment(call.result) if copy_attachments
      end
    end

    def build(meeting, attribute_overrides)
      Meetings::SetAttributesService
        .new(user:, model: meeting.dup, contract_class:)
        .call(**copied_attributes(meeting, attribute_overrides).symbolize_keys)
    end

    def copied_attributes(meeting, override)
      overwritten_attributes = override.stringify_keys

      meeting
        .attributes
        .slice(*writable_meeting_attributes(meeting))
        .merge("start_time" => meeting.start_time + 1.week)
        .merge("author" => user)
        .merge("state" => "open")
        .merge("participants_attributes" => copied_participants)
        .merge(overwritten_attributes)
    end

    def copied_participants
      if meeting.allowed_participants.empty?
        [{ "user_id" => user.id, "invited" => true }]
      else
        meeting.allowed_participants.collect(&:copy_attributes)
      end
    end

    def writable_meeting_attributes(meeting)
      instantiate_contract(meeting, user).writable_attributes - %w[start_date start_time_hour]
    end

    def copy_meeting_attachment(copy)
      copy_attachments(
        "Meeting",
        from: meeting,
        to: copy
      )
    end

    def update_references(attachment_source:, attachment_target:, model_source:, model_target:, references:)
      model_target
        .agenda_items
        .update_all(["notes = REPLACE(notes, '/attachments/?/', '/attachments/?/')",
                     attachment_source,
                     attachment_target])
    end

    def copy_meeting_agenda(copy)
      if meeting.is_a?(StructuredMeeting)
        meeting.sections.each do |section|
          copy.sections << section.dup
          copied_section = copy.reload.sections.last
          section.agenda_items.each do |agenda_item|
            copied_agenda_item = agenda_item.dup
            copied_agenda_item.meeting_id = copy.id
            copied_section.agenda_items << copied_agenda_item
          end
        end
      else
        MeetingAgenda.create!(
          meeting: copy,
          author: user,
          text: meeting.agenda&.text,
          journal_notes: I18n.t("meeting.copied", id: meeting.id)
        )
      end
    end
  end
end
