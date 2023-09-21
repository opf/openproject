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
  class MeetingComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_agenda_items:)
      super

      @meeting = meeting
      @meeting_agenda_items = meeting_agenda_items
    end

    def call
      render(Primer::Beta::BorderBox.new(padding: :condensed)) do |border_box|
        border_box.with_header do
          header_partial
        end
        @meeting_agenda_items.each do |meeting_agenda_item|
          border_box.with_row do
            render(WorkPackageMeetingsTab::MeetingAgendaItemComponent.new(meeting_agenda_item:))
          end
        end
      end
    end

    private

    def header_partial
      flex_layout do |flex|
        flex.with_column(mr: 1) do
          meeting_link_partial
        end
        flex.with_column do
          meeting_time_partial
        end
      end
    end

    def meeting_link_partial
      render(Primer::Beta::Link.new(href: meeting_path(@meeting), target: "_blank", font_size: :normal,
                                    font_weight: :bold, scheme: :primary, underline: false)) do
        @meeting.title
      end
    end

    def meeting_time_partial
      render(Primer::Beta::Text.new(font_size: :normal, color: :muted)) do
        format_time(@meeting.start_time)
      end
    end
  end
end
