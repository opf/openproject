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

module MeetingAgendaItems
  class ListComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper(data: wrapper_data_attributes) do
        render(Primer::Beta::BorderBox.new(padding: :condensed)) do |border_box|
          @meeting.agenda_items.each do |meeting_agenda_item|
            row_partial(border_box, meeting_agenda_item)
          end
        end
      end
    end

    private

    def wrapper_data_attributes
      {
        controller: 'meeting-agenda-item-drag-and-drop',
        'application-target': 'dynamic',
        'target-tag': 'ul'
      }
    end

    def row_partial(border_box, meeting_agenda_item)
      border_box.with_row(
        scheme: :default,
        data: {
          id: meeting_agenda_item.id,
          'drop-url': drop_meeting_agenda_item_path(meeting_agenda_item.meeting, meeting_agenda_item)
        }
      ) do
        render(MeetingAgendaItems::ItemComponent.new(meeting_agenda_item:))
      end
    end
  end
end
