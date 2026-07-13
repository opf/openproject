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
  class DuplicateInNextMeetingDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(agenda_item:, datetime:, skipped_cancelled: nil, skipped_closed: nil, next_occurrence: nil)
      super

      @agenda_item = agenda_item
      @datetime = datetime
      @skipped_cancelled = skipped_cancelled
      @skipped_closed = skipped_closed
      @next_occurrence = next_occurrence
    end

    private

    def title = I18n.t(:label_agenda_item_duplicate_in_next_title)

    def confirmation_message
      base_message = I18n.t(
        :text_agenda_item_duplicate_in_next_meeting,
        date: format_date(@datetime),
        time: format_time(@datetime, include_date: false)
      )

      note = skipped_note
      note.present? ? "#{base_message}\n\n#{note}" : base_message
    end

    def skipped_note
      parts = []
      parts << skipped_cancelled_part if @skipped_cancelled.present?
      parts << skipped_closed_part if @skipped_closed.present?
      return if parts.empty?

      I18n.t(:text_agenda_item_dialog_skipping_note, details: parts.to_sentence)
    end

    def skipped_cancelled_part
      if @skipped_cancelled.one?
        I18n.t(:text_agenda_item_dialog_skipping_cancelled_one, date: format_date(@skipped_cancelled.first))
      else
        I18n.t(:text_agenda_item_dialog_skipping_cancelled_many, count: @skipped_cancelled.size)
      end
    end

    def skipped_closed_part
      if @skipped_closed.one?
        I18n.t(:text_agenda_item_dialog_skipping_closed_one, date: format_date(@skipped_closed.first))
      else
        I18n.t(:text_agenda_item_dialog_skipping_closed_many, count: @skipped_closed.size)
      end
    end
  end
end
