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
  class ItemComponent::EditComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:, display_notes_input: nil)
      super

      @meeting_agenda_item = meeting_agenda_item
      @type = @meeting_agenda_item.item_type.to_sym
      @display_notes_input = display_notes_input
    end

    def call
      render(Primer::Box.new(pl: 3)) do
        render(MeetingAgendaItems::FormComponent.new(
                 meeting: @meeting_agenda_item.meeting,
                 meeting_section: @meeting_agenda_item.meeting_section,
                 meeting_agenda_item: @meeting_agenda_item,
                 method: :put,
                 submit_path: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item, format: :turbo_stream),
                 cancel_path: cancel_edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
                 type: @type,
                 display_notes_input: @display_notes_input
               ))
      end
    end
  end
end
