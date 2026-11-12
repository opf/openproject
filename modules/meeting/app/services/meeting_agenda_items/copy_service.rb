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
  class CopyService
    include ::Shared::ServiceContext
    include Concerns::CopyAttachments

    def initialize(user:, model:)
      @user = user
      @agenda_item = model
    end

    def call(include_outcomes: false, attributes: {})
      in_user_context do
        copy = MeetingAgendaItem.new
        copy_outcomes(copy) if include_outcomes

        MeetingAgendaItems::CreateService
          .new(user:, model: copy)
          .call(copied_attributes(attributes))
          .on_success { |call| copy_referenced_attachments(call.result) }
      end
    end

    private

    attr_reader :user, :agenda_item

    def copied_attributes(override)
      agenda_item
        .copy_attributes
        .except("author_id", "created_at", "updated_at", "lock_version", "position", "meeting_section_id")
        .merge(override.stringify_keys)
        .symbolize_keys
    end

    def copy_outcomes(copy)
      agenda_item.outcomes.reject(&:deleted_work_package?).each do |outcome|
        copy.outcomes.build(outcome.copy_attributes.merge("author" => user))
      end
    end

    def copy_referenced_attachments(copy)
      [copy, *copy.outcomes].each do |record|
        copy_attachments_from_meeting(record, agenda_item.meeting_id)
      end

      copy.meeting.save_journals
    end
  end
end
