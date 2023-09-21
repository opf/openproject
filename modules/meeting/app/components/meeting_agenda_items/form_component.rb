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
  class FormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_agenda_item:, method:, submit_path:, cancel_path:, type: :simple)
      super

      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item
      @method = method
      @submit_path = submit_path
      @cancel_path = cancel_path
      @type = type
    end

    def call
      component_wrapper(data: wrapper_data_attributes) do
        primer_form_with(
          model: @meeting_agenda_item,
          method: @method,
          url: @submit_path
        ) do |f|
          form_content_partial(f)
        end
      end
    end

    def render?
      User.current.allowed_in_project?(:edit_meetings, @meeting.project)
    end

    private

    def wrapper_data_attributes
      {
        controller: 'meeting-agenda-item-form',
        'application-target': 'dynamic',
        'meeting-agenda-item-form-cancel-url-value': @cancel_path
      }
    end

    def form_content_partial(form)
      flex_layout do |flex|
        flex.with_row do
          form_fields_partial(form)
        end
        flex.with_row(mt: 2) do
          form_notes_partial(form)
        end
        flex.with_row do
          form_actions_partial(form)
        end
      end
    end

    def form_fields_partial(form)
      flex_layout do |flex|
        flex.with_column(flex: 1) do
          case @type
          when :simple
            render(MeetingAgendaItem::Title.new(form))
          when :work_package
            render(MeetingAgendaItem::WorkPackage.new(form))
          end
        end
        flex.with_column(ml: 2) do
          render(MeetingAgendaItem::Duration.new(form))
        end
      end
    end

    def form_notes_partial(form)
      render(Primer::Box.new(data: { 'meeting-agenda-item-form-target': "notesInput" },
                             display: display_notes_input_value)) do
        render(MeetingAgendaItem::Notes.new(form))
      end
    end

    def display_notes_input_value
      @meeting_agenda_item.notes.blank? ? :none : nil
    end

    def form_actions_partial(form)
      flex_layout(justify_content: :space_between, mt: 2) do |flex|
        flex.with_column do
          additional_elements_partial
        end
        flex.with_column do
          save_or_cancel_partial(form)
        end
      end
    end

    def additional_elements_partial
      render(Primer::Beta::Button.new(
               scheme: :secondary,
               display: display_notes_add_button_value,
               data: {
                 'meeting-agenda-item-form-target': "notesAddButton",
                 action: 'click->meeting-agenda-item-form#addNotes keydown.enter->meeting-agenda-item-form#addNotes'
               }
             )) do |component|
        component.with_leading_visual_icon(icon: :plus)
        MeetingAgendaItem.human_attribute_name(:notes)
      end
    end

    def display_notes_add_button_value
      @meeting_agenda_item.notes.blank? ? nil : :none
    end

    def save_or_cancel_partial(form)
      flex_layout(justify_content: :flex_end) do |flex|
        flex.with_column(mr: 2) do
          back_link_partial
        end
        flex.with_column do
          render(MeetingAgendaItem::Submit.new(form, type: @type))
        end
      end
    end

    def back_link_partial
      render(Primer::Beta::Button.new(
               scheme: :secondary,
               tag: :a,
               href: @cancel_path,
               data: { 'turbo-stream': true }
             )) do |_c|
        t("button_cancel")
      end
    end
  end
end
