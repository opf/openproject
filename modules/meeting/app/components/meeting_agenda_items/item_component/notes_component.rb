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
  class ItemComponent::NotesComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(meeting_agenda_item:, state: :initial)
      super

      @meeting_agenda_item = meeting_agenda_item
      @state = state
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    def call
      component_wrapper do
        case @state
        when :initial
          initial_state_partial
        when :edit
          edit_state_partial
        end
      end
    end

    private

    def initial_state_partial
      flex_layout do |flex|
        if @meeting_agenda_item.details.present?
          flex.with_row do
            notes_display_partial
          end
        else
          flex.with_row(mt: 1) do
            add_notes_button_partial
          end
        end
      end
    end

    def notes_display_partial
      render(Primer::Box.new(font_size: :small, bg: :subtle, border: true, border_radius: 2, p: 3)) do
        flex_layout do |flex|
          flex.with_row do
            notes_content_partial
          end
          flex.with_row(mt: 2, ml: 4) do
            add_notes_button_partial("Edit notes")
          end
        end
      end
    end

    def notes_content_partial
      flex_layout do |flex|
        flex.with_column(mr: 2) do
          render(Primer::Beta::Octicon.new(icon: "note", 'aria-label': "open", color: :muted))
        end
        flex.with_column do
          simple_format(@meeting_agenda_item.details, {}, wrapper_tag: "span")
        end
      end
    end

    def add_notes_button_partial(text = "Add notes")
      return if @meeting_agenda_item.meeting.agenda_items_closed?

      render(Primer::Beta::Button.new(
               scheme: :secondary,
               size: :small,
               tag: :a,
               href: edit_notes_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
               data: { 'turbo-stream': true }
             )) do |_c|
        text
      end
    end

    def edit_state_partial
      primer_form_with(
        model: @meeting_agenda_item,
        url: submit_path
      ) do |form|
        flex_layout do |flex|
          flex.with_row(mt: 2) do
            render(MeetingAgendaItem::Details.new(form))
          end
          flex.with_row(flex_layout: true, justify_content: :flex_end, mt: 2) do |flex|
            flex.with_column(mr: 2) do
              back_link_partial
            end
            flex.with_column do
              render(MeetingAgendaItem::Submit.new(form))
            end
          end
        end
      end
    end

    def submit_path
      save_notes_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item)
    end

    def back_link_partial
      render(Primer::Beta::Button.new(
               scheme: :secondary,
               tag: :a,
               href: cancel_edit_notes_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
               data: { confirm: 'Are you sure?', 'turbo-stream': true }
             )) do |_c|
        "Cancel"
      end
    end
  end
end
