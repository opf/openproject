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
  class ItemComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    with_collection_parameter :meeting_agenda_item

    def initialize(
      meeting_agenda_item:,
      state: :show,
      container: nil,
      display_notes_input: nil,
      first_and_last: []
    )
      super

      @meeting_agenda_item = meeting_agenda_item
      @state = state
      @display_notes_input = display_notes_input
      @container = container
      @first_and_last = first_and_last
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    def call
      component_wrapper(:border_box_row, **wrapper_arguments) do
        case @state
        when :show
          render(MeetingAgendaItems::ItemComponent::ShowComponent.new(**show_component_params))
        when :edit
          render(MeetingAgendaItems::ItemComponent::EditComponent.new(**child_component_params))
        end
      end
    end

    private

    attr_reader :container

    def child_component_params
      {
        meeting_agenda_item: @meeting_agenda_item,
        display_notes_input: (@display_notes_input if @state == :edit)
      }.compact
    end

    def show_component_params
      child_component_params.merge(first_and_last: @first_and_last).compact
    end

    def wrapper_arguments
      {
        pl: 0,
        scheme: :default,
        data: {
          id: @meeting_agenda_item.id,
          "draggable-id": @meeting_agenda_item.id,
          "draggable-type": "agenda-item",
          "drop-url": drop_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item)
        }
      }
    end
  end
end
