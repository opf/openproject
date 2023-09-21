#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module WorkPackageMeetingsTab
  class MeetingAgendaItemComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:)
      super

      @meeting_agenda_item = meeting_agenda_item
    end

    def call
      flex_layout do |flex|
        flex.with_row do
          notes_partial
        end
        flex.with_row(mt: 3, font_size: :small) do
          author_partial
        end
      end
    end

    private

    def notes_partial
      if @meeting_agenda_item.notes.present?
        render(Primer::Beta::Text.new) do
          ::OpenProject::TextFormatting::Renderer.format_text(@meeting_agenda_item.notes)
        end
      else
        render(Primer::Beta::Text.new(color: :subtle)) do
          t("text_agenda_item_no_notes")
        end
      end
    end

    def author_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          render(Primer::Beta::Text.new(color: :subtle)) { t("label_added_by", author: nil) }
        end
        flex.with_column(mr: 1) do
          render(Users::AvatarComponent.new(user: @meeting_agenda_item.author, size: 'mini'))
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(color: :subtle, datetime: @meeting_agenda_item.created_at))
        end
      end
    end
  end
end
