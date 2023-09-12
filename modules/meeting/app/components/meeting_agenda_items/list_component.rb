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
  class ListComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, form_hidden: true, form_type: :simple)
      super

      @meeting = meeting
      @form_hidden = form_hidden
      @form_type = form_type
    end

    def call
      component_wrapper(data: wrapper_data_attributes) do
        render(Primer::Beta::BorderBox.new) do |border_box|
          if @meeting.agenda_items.empty? && @form_hidden
            empty_state_partial(border_box)
          else
            @meeting.agenda_items.each do |meeting_agenda_item|
              row_partial(border_box, meeting_agenda_item)
            end
          end
          border_box.with_row(p: 0, border_top: 0) do
            new_form_partial
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

    def empty_state_partial(border_box)
      border_box.with_body(
        scheme: :default
      ) do
        blank_slate_partial
      end
    end

    def blank_slate_partial
      render(Primer::Beta::Blankslate.new) do |component|
        component.with_visual_icon(icon: :book)
        component.with_heading(tag: :h2).with_content(t("text_meeting_empty_heading"))
        component.with_description do
          flex_layout do |flex|
            flex.with_row(mb: 2) do
              render(Primer::Beta::Text.new(color: :subtle)) { t("text_meeting_empty_description_1") }
            end
            flex.with_row do
              render(Primer::Beta::Text.new(color: :subtle)) { t("text_meeting_empty_description_2") }
            end
          end
        end
        # component.with_primary_action(href: "#").with_content(t("label_meeting_empty_action"))
      end
    end

    def row_partial(border_box, meeting_agenda_item)
      border_box.with_row(
        pl: 0,
        scheme: :default,
        data: {
          id: meeting_agenda_item.id,
          'drop-url': drop_meeting_agenda_item_path(meeting_agenda_item.meeting, meeting_agenda_item)
        }
      ) do
        render(MeetingAgendaItems::ItemComponent.new(meeting_agenda_item:))
      end
    end

    def new_form_partial
      render(MeetingAgendaItems::NewComponent.new(meeting: @meeting, hidden: @form_hidden, type: @form_type))
    end
  end
end
