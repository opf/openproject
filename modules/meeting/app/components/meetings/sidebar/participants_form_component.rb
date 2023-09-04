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

module Meetings
  class Sidebar::ParticipantsFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpenProject::FormTagHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        form_partial
      end
    end

    def render?
      User.current.allowed_to?(:edit_meetings, @meeting.project)
    end

    private

    def form_partial
      primer_form_with(
        model: @meeting,
        method: :put,
        url: update_participants_meeting_path(@meeting)
      ) do |f|
        component_collection do |collection|
          collection.with_component(Primer::Alpha::Dialog::Body.new(style: "max-height: 460px;", my: 3)) do
            flex_layout(mt: 3) do |flex|
              flex.with_row do
                header_partial
              end
              flex.with_row do
                form_content_partial(f)
              end
            end
          end
          collection.with_component(Primer::Alpha::Dialog::Footer.new(show_divider: true)) do
            form_actions_partial
          end
        end
      end
    end

    def header_partial
      flex_layout(justify_content: :flex_end) do |flex|
        flex.with_column(style: "width: 90px;", text_align: :center) do
          render(Primer::Beta::Text.new(font_weight: :emphasized)) { t("description_invite").capitalize }
        end
        flex.with_column(style: "width: 90px;", text_align: :center) do
          render(Primer::Beta::Text.new(font_weight: :emphasized)) { t("description_attended").capitalize }
        end
      end
    end

    def form_content_partial(_form)
      flex_layout(my: 3) do |flex|
        @meeting.all_changeable_participants.sort.each do |user|
          flex.with_row do
            hidden_field_tag "meeting[participants_attributes][][user_id]", user.id
          end
          participant_form_partial(user, flex)
        end
      end
    end

    def participant_form_partial(user, flex)
      flex.with_row(mb: 2, pb: 1, border: :bottom) do
        if @meeting.participants.present? && participant = @meeting.participants.detect { |p| p.user_id == user.id }
          exisiting_participant_form_partial(participant)
        else
          new_participant_form_partial(user)
        end
      end
    end

    def exisiting_participant_form_partial(participant)
      flex_layout do |flex|
        flex.with_row do
          hidden_field_tag "meeting[participants_attributes][][id]", participant.id
        end
        flex.with_row do
          exisiting_participant_form_checkboxes_partial(participant)
        end
      end
    end

    def exisiting_participant_form_checkboxes_partial(participant)
      flex_layout(align_items: :center) do |flex|
        flex.with_column(flex: 1) do
          render(Users::AvatarComponent.new(
                   user: participant.user,
                   text_system_attributes: {
                     font_size: :normal, muted: false
                   }
                 ))
        end
        flex.with_column(style: "width: 90px;", text_align: :center) do
          invited_participant_checkbox_partial(participant)
        end
        flex.with_column(style: "width: 90px;", text_align: :center) do
          attended_participant_checkbox_partial(participant)
        end
      end
    end

    def invited_participant_checkbox_partial(participant)
      styled_check_box_tag "meeting[participants_attributes][][invited]", 1, participant.invited?,
                           id: "checkbox_invited_#{participant.user.id}"
      # Primer checkboxes currently not working in this context as they render an additional hidden input tag
      # messing up the nested attributes mapping when posting the data to the server
      #
      # render(Primer::Alpha::CheckBox.new(
      #          name: "meeting[participants_attributes][][invited]",
      #          checked: participant.invited?,
      #          id: "checkbox_invited_#{participant.user.id}",
      #          visually_hide_label: true,
      #          label: "Invited",
      #          scheme: :boolean,
      #          unchecked_value: ""
      #        ))
    end

    def attended_participant_checkbox_partial(participant)
      styled_check_box_tag "meeting[participants_attributes][][attended]", 1, participant.attended?,
                           id: "checkbox_attended_#{participant.user.id}"
      # Primer checkboxes currently not working in this context as they render an additional hidden input tag
      # messing up the nested attributes mapping when posting the data to the server
      #
      # render(Primer::Alpha::CheckBox.new(
      #          name: "meeting[participants_attributes][][attended]",
      #          checked: participant.attended?,
      #          id: "checkbox_attended_#{participant.user.id}",
      #          visually_hide_label: true,
      #          label: "Attended",
      #          scheme: :boolean,
      #          unchecked_value: ""
      #        ))
    end

    def new_participant_form_partial(user)
      flex_layout(align_items: :center) do |flex|
        flex.with_column(flex: 1) do
          render(Users::AvatarComponent.new(
                   user:,
                   text_system_attributes: {
                     font_size: :normal, muted: false
                   }
                 ))
        end
        flex.with_column(style: "width: 90px;", text_align: :center) do
          invited_user_checkbox_partial(user)
        end
        flex.with_column(style: "width: 90px;", text_align: :center) do
          attended_user_checkbox_partial(user)
        end
      end
    end

    def invited_user_checkbox_partial(user)
      styled_check_box_tag "meeting[participants_attributes][][invited]", value = "1", checked = false,
                           id: "checkbox_invited_#{user.id}"
      # Primer checkboxes currently not working in this context as they render an additional hidden input tag
      # messing up the nested attributes mapping when posting the data to the server
      #
      # render(Primer::Alpha::CheckBox.new(
      #          name: "meeting[participants_attributes][][invited]",
      #          id: "checkbox_invited_#{user.id}",
      #          visually_hide_label: true,
      #          label: "Invited",
      #          scheme: :boolean,
      #          unchecked_value: ""
      #        ))
    end

    def attended_user_checkbox_partial(user)
      styled_check_box_tag "meeting[participants_attributes][][attended]", value = "1", checked = false,
                           id: "checkbox_attended_#{user.id}"
      # Primer checkboxes currently not working in this context as they render an additional hidden input tag
      # messing up the nested attributes mapping when posting the data to the server
      #
      # render(Primer::Alpha::CheckBox.new(
      #          name: "meeting[participants_attributes][][attended]",
      #          id: "checkbox_attended_#{user.id}",
      #          visually_hide_label: true,
      #          label: "Attended",
      #          scheme: :boolean,
      #          unchecked_value: ""
      #        ))
    end

    def form_actions_partial
      component_collection do |collection|
        collection.with_component(Primer::ButtonComponent.new(data: { 'close-dialog-id': "edit-participants-dialog" })) do
          t("button_cancel")
        end
        collection.with_component(Primer::ButtonComponent.new(scheme: :primary, type: :submit)) do
          t("button_save")
        end
      end
    end
  end
end
