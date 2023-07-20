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
  class FormComponent < Base::OpTurbo::Component
    def initialize(meeting:, meeting_agenda_item:, active_work_package: nil, method:, submit_path:, cancel_path:, **kwargs)
      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item
      @active_work_package = active_work_package
      @method = method
      @submit_path = submit_path
      @cancel_path = cancel_path
    end

    def call
      component_wrapper(data: wrapper_data_attributes) do
        primer_form_with(
          model: @meeting_agenda_item, 
          method: :post,
          method: @method, 
          url: @submit_path
        ) do |f|
          flex_layout do |flex|
            flex.with_row do
              hidden_field_tag :work_package_id, @active_work_package&.id
            end
            flex.with_row(flex_layout: true) do |flex|
              flex.with_column(flex: 1, flex_layout: true, mr: 5) do |flex|
                flex.with_column(flex: 1, data: { "meeting-agenda-item-form-target": "titleInput" }, display: display_title_input_value) do
                  render(MeetingAgendaItem::New::Title.new(f))
                end
                unless @active_work_package.present?
                  flex.with_column(flex: 1, data: { "meeting-agenda-item-form-target": "workPackageInput" }, display: display_work_package_input_value) do
                    render(MeetingAgendaItem::New::WorkPackage.new(f))
                  end
                  flex.with_column(ml: 2, data: { "meeting-agenda-item-form-target": "workPackageButton" }, display: display_work_package_button_value) do
                    render(Primer::Beta::Button.new(data: { action: 'click->meeting-agenda-item-form#addWorkPackage keydown.enter->meeting-agenda-item-form#addWorkPackage' })) do |button|
                      "Reference work package instead"
                    end
                  end
                end
              end
              unless @active_work_package.present?
                flex.with_column(ml: 2) do
                  render(MeetingAgendaItem::New::Duration.new(f))
                end
                flex.with_column(ml: 2) do
                  render(MeetingAgendaItem::New::Author.new(f))
                end
              end
            end
            flex.with_row(mt: 2, data: { "meeting-agenda-item-form-target": "detailsInput" }, display: display_details_input_value) do
              render(MeetingAgendaItem::New::Details.new(f))
            end
            flex.with_row(mt: 2, data: { "meeting-agenda-item-form-target": "clarificationNeedInput" }, display: display_clarification_need_input_value) do
              render(MeetingAgendaItem::New::ClarificationNeed.new(f))
            end
            flex.with_row(mt: 2, data: { "meeting-agenda-item-form-target": "clarificationInput" }, display: display_clarification_input_value) do
              render(MeetingAgendaItem::New::Clarification.new(f))
            end
            flex.with_row(mt: 2) do
              action_menu_partial
            end
            flex.with_row(flex_layout: true, justify_content: :flex_end, mt: 2) do |flex|
              flex.with_column do
                render(MeetingAgendaItem::New::Submit.new(f, preselected_work_package: @active_work_package))
              end
            end
          end
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

    def display_title_input_value
      @meeting_agenda_item.work_package.present? ? :none : :block
    end

    def display_work_package_button_value
      display_title_input_value
    end

    def display_work_package_input_value
      @meeting_agenda_item.work_package.nil? ? :none : nil
    end

    def display_details_input_value
      @meeting_agenda_item.details.blank? ? :none : nil
    end

    def display_clarification_need_input_value
      @meeting_agenda_item.input.blank? ? :none : nil
    end

    def display_clarification_input_value
      @meeting_agenda_item.output.blank? ? :none : nil
    end

    def action_menu_partial
      if @meeting_agenda_item.details.blank? || @meeting_agenda_item.input.blank? || @meeting_agenda_item.output.blank?
        render(Primer::Alpha::ActionMenu.new(menu_id: "new-meeting-agenda-item-additional-fields-menu")) do |menu| 
          menu.with_show_button { |button| button.with_trailing_action_icon(icon: :"triangle-down"); "Add" }
          menu.with_item(label: "Details", data: { action: 'click->meeting-agenda-item-form#addDetails keydown.enter->meeting-agenda-item-form#addDetails' }) if @meeting_agenda_item.details.blank?
          menu.with_item(label: "Clarification need", data: { action: 'click->meeting-agenda-item-form#addClarificationNeed keydown.enter->meeting-agenda-item-form#addClarificationNeed' }) if @meeting_agenda_item.input.blank?
          menu.with_item(label: "Clarification", data: { action: 'click->meeting-agenda-item-form#addClarification keydown.enter->meeting-agenda-item-form#addClarifciation' }) if @meeting_agenda_item.output.blank?
        end
      end
    end

  end
end
