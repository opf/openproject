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

    private

    def form_partial
      primer_form_with(
        model: @meeting,
        method: :put,
        url: meeting_path(@meeting)
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
        flex.with_column(mr: 4) { "Invited" }
        flex.with_column(mr: 2) { "Attended" }
      end
    end

    def form_content_partial(_form)
      flex_layout(my: 3) do |flex|
        @meeting.all_changeable_participants.sort.each do |user|
          flex.with_row do
            hidden_field_tag "meeting[participants_attributes][][user_id]", user.id
          end
          flex.with_row(mb: 2, pb: 1, border: :bottom) do
            if @meeting.participants.present? && participant = @meeting.participants.detect { |p| p.user_id == user.id }
              flex_layout do |flex|
                flex.with_row do
                  hidden_field_tag "meeting[participants_attributes][][id]", participant.id
                end
                flex.with_row do
                  exisiting_participant_form_partial(participant)
                end
              end
            else
              new_participant_form_partial(user)
            end
          end
        end
      end
    end

    def exisiting_participant_form_partial(participant)
      flex_layout(align_items: :center) do |flex|
        flex.with_column(flex: 1) do
          render(Users::AvatarComponent.new(
                   user: participant.user,
                   text_system_attributes: {
                     font_size: :normal, muted: false
                   }
                 ))
        end
        flex.with_column(mx: 4) do
          invited_participant_checkbox_partial(participant)
        end
        flex.with_column(mx: 4) do
          attended_participant_checkbox_partial(participant)
        end
      end
    end

    def invited_participant_checkbox_partial(participant)
      render(Primer::Alpha::CheckBox.new(
               name: "meeting[participants_attributes][][invited]",
               checked: participant.invited?,
               id: "checkbox_invited_#{participant.user.id}",
               visually_hide_label: true,
               label: "Invited",
               scheme: :boolean,
               unchecked_value: ""
             ))
    end

    def attended_participant_checkbox_partial(participant)
      render(Primer::Alpha::CheckBox.new(
               name: "meeting[participants_attributes][][attended]",
               checked: participant.attended?,
               id: "checkbox_attended_#{participant.user.id}",
               visually_hide_label: true,
               label: "Attended",
               scheme: :boolean,
               unchecked_value: ""
             ))
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
        flex.with_column(mx: 4) do
          invited_user_checkbox_partial(user)
        end
        flex.with_column(mx: 4) do
          attended_user_checkbox_partial(user)
        end
      end
    end

    def invited_user_checkbox_partial(user)
      render(Primer::Alpha::CheckBox.new(
               name: "meeting[participants_attributes][][invited]",
               id: "checkbox_invited_#{user.id}",
               visually_hide_label: true,
               label: "Invited",
               scheme: :boolean,
               unchecked_value: ""
             ))
    end

    def attended_user_checkbox_partial(user)
      render(Primer::Alpha::CheckBox.new(
               name: "meeting[participants_attributes][][attended]",
               id: "checkbox_attended_#{user.id}",
               visually_hide_label: true,
               label: "Attended",
               scheme: :boolean,
               unchecked_value: ""
             ))
    end

    # <% if @meeting.participants.present? && participant = @meeting.participants.detect{|p| p.user_id == user.id} -%>
    #   <%= hidden_field_tag "meeting[participants_attributes][][id]", participant.id %>
    #   <td class="form--matrix-checkbox-cell">
    #     <%= label_tag "checkbox_invited_#{user.id}", user.name + " " + t(:description_invite), :class => "hidden-for-sighted" %>
    #     <%= styled_check_box_tag "meeting[participants_attributes][][invited]", 1, participant.invited?, :id => "checkbox_invited_#{user.id}" %>
    #   </td>
    #   <td class="form--matrix-checkbox-cell">
    #     <%= label_tag "checkbox_attended_#{user.id}", user.name + " " + t(:description_attended), :class => "hidden-for-sighted" %>
    #     <%= styled_check_box_tag "meeting[participants_attributes][][attended]", 1, participant.attended?, :id => "checkbox_attended_#{user.id}" %>
    #   </td>
    # <% else -%>
    #   <td class="form--matrix-checkbox-cell">
    #     <%= label_tag "checkbox_invited_#{user.id}", user.name + " " + t(:description_invite), :class => "hidden-for-sighted" %>
    #     <%= styled_check_box_tag "meeting[participants_attributes][][invited]", value = "1", checked = false, :id => "checkbox_invited_#{user.id}" %>
    #   </td>
    #   <td class="form--matrix-checkbox-cell">
    #     <%= label_tag "checkbox_attended_#{user.id}", user.name + " " + t(:description_attended), :class => "hidden-for-sighted" %>
    #     <%= styled_check_box_tag "meeting[participants_attributes][][attended]", value = "1", checked = false, :id => "checkbox_attended_#{user.id}" %>
    #   </td>
    # <% end -%>

    def form_actions_partial
      component_collection do |collection|
        collection.with_component(Primer::ButtonComponent.new(data: { 'close-dialog-id': "edit-participants-dialog" })) do
          "Cancel"
        end
        collection.with_component(Primer::ButtonComponent.new(scheme: :primary, type: :submit, disabled: true)) do
          "Submit (to-do)"
        end
      end
    end
  end
end
