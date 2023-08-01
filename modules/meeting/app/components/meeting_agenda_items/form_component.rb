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
  class FormComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(meeting:, meeting_agenda_item:, method:, submit_path:, cancel_path:)
      super

      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item
      @method = method
      @submit_path = submit_path
      @cancel_path = cancel_path
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

    private

    def wrapper_data_attributes
      {
        controller: 'meeting-agenda-item-form',
        'application-target': 'dynamic',
        'meeting-agenda-item-form-cancel-url-value': @cancel_path
      }
    end

    def form_content_partial(f)
      flex_layout do |flex|
        flex.with_row(flex_layout: true) do |flex|
          flex.with_column(flex: 1, flex_layout: true, mr: 5) do |flex|
            flex.with_column(flex: 1, data: { 'meeting-agenda-item-form-target': "titleInput" },
                             display: display_title_input_value) do
              render(MeetingAgendaItem::Title.new(f, disabled: !@meeting.agenda_items_open?))
            end
            flex.with_column(flex: 1, data: { 'meeting-agenda-item-form-target': "issueInput" },
                             display: display_issue_input_value) do
              render(MeetingAgendaItem::Issue.new(f, disabled: !@meeting.agenda_items_open?))
            end
            if @meeting.agenda_items_open?
              flex.with_column(ml: 2, data: { 'meeting-agenda-item-form-target': "issueButton" },
                               display: display_issue_button_value) do
                render(Primer::Beta::Button.new(data: { action: 'click->meeting-agenda-item-form#addIssue keydown.enter->meeting-agenda-item-form#addIssue' })) do |_button|
                  "Reference issue instead"
                end
              end
            end
          end
          flex.with_column(ml: 2) do
            render(MeetingAgendaItem::Duration.new(f, disabled: !@meeting.agenda_items_open?))
          end
          # flex.with_column(ml: 2) do
          #   render(MeetingAgendaItem::Author.new(f, disabled: !@meeting.agenda_items_open?))
          # end
        end
        # flex.with_row(mt: 2) do
        #   action_menu_partial
        # end
        flex.with_row(flex_layout: true, justify_content: :flex_end, mt: 2) do |flex|
          flex.with_column(mr: 2) do
            back_link_partial
          end
          flex.with_column do
            render(MeetingAgendaItem::Submit.new(f))
          end
        end
      end
    end

    def display_title_input_value
      @meeting_agenda_item.work_package_issue.present? ? :none : :block
    end

    def display_issue_button_value
      display_title_input_value
    end

    def display_issue_input_value
      @meeting_agenda_item.work_package_issue.nil? ? :none : nil
    end

    def display_details_input_value
      @meeting_agenda_item.details.blank? ? :none : nil
    end

    def action_menu_partial
      if @meeting_agenda_item.details.blank?
        render(Primer::Alpha::ActionMenu.new(menu_id: "meeting-agenda-item-additional-fields-menu-#{@meeting_agenda_item.id || 'new'}")) do |menu|
          menu.with_show_button do |button|
            button.with_trailing_action_icon(icon: :'triangle-down')
            "Add"
          end
          if @meeting_agenda_item.details.blank?
            menu.with_item(label: "Details",
                           data: { action: 'click->meeting-agenda-item-form#addDetails keydown.enter->meeting-agenda-item-form#addDetails' })
          end
        end
      end
    end

    def back_link_partial
      render(Primer::Beta::Button.new(
               scheme: :secondary,
               tag: :a,
               href: @cancel_path,
               data: { confirm: 'Are you sure?', 'turbo-stream': true }
             )) do |_c|
        "Cancel"
      end
    end
  end
end
