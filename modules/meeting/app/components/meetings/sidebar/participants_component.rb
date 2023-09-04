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
  class Sidebar::ParticipantsComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        flex_layout do |flex|
          flex.with_row do
            heading_partial
          end
          flex.with_row(mt: 2) do
            participant_list_partial(5)
          end
          if edit_enabled?
            flex.with_row(mt: 3) do
              manage_button_partial
            end
          end
        end
      end
    end

    private

    def edit_enabled?
      User.current.allowed_to?(:edit_meetings, @meeting.project)
    end

    def heading_partial
      flex_layout(align_items: :center, justify_content: :space_between) do |flex|
        flex.with_column(flex: 1) do
          title_partial
        end
        if edit_enabled?
          flex.with_column do
            dialog_wrapper_partial
          end
        end
      end
    end

    def title_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          render(Primer::Beta::Heading.new(tag: :h4)) { Meeting.human_attribute_name(:participants) }
        end
        flex.with_column do
          render(Primer::Beta::Counter.new(count: @meeting.invited_or_attended_participants.count, scheme: :primary))
        end
      end
    end

    def dialog_wrapper_partial
      render(Primer::Alpha::Dialog.new(
               id: "edit-participants-dialog", title: Meeting.human_attribute_name(:participants),
               size: :medium_portrait
             )) do |dialog|
        dialog.with_show_button(icon: :gear, 'aria-label': t("label_meeting_manage_participants"), scheme: :invisible)
        render(Meetings::Sidebar::ParticipantsFormComponent.new(meeting: @meeting))
      end
    end

    def participant_list_partial(max_initially_shown_participants)
      count = @meeting.invited_or_attended_participants.count

      if count == 0
        render(Primer::Beta::Text.new(color: :subtle)) { t("label_meeting_no_participants") }
      elsif count <= max_initially_shown_participants
        unsplit_participant_list
      elsif count > max_initially_shown_participants
        split_participant_list(max_initially_shown_participants)
      end
    end

    def unsplit_participant_list
      flex_layout do |flex|
        @meeting.invited_or_attended_participants.sort.each do |participant|
          flex.with_row(mt: 1) do
            participant_partial(participant)
          end
        end
      end
    end

    def split_participant_list(max_initially_shown_participants)
      flex_layout do |flex|
        @meeting.invited_or_attended_participants.sort.take(max_initially_shown_participants).each do |participant|
          flex.with_row(mt: 1) do
            participant_partial(participant)
          end
        end
        flex.with_row(mt: 2) do
          more_participants_partial(max_initially_shown_participants)
        end
      end
    end

    def more_participants_partial(max_initially_shown_participants)
      render Primer::Beta::Details.new do |component|
        flex_layout do |flex|
          flex.with_row do
            component.with_summary(size: :small, scheme: :link) do
              t('label_meeting_show_hide_participants',
                count: @meeting.invited_or_attended_participants.count - max_initially_shown_participants).to_s
            end
          end
          flex.with_row do
            component.with_body do
              hidden_participants_partial(max_initially_shown_participants)
            end
          end
        end
      end
    end

    def hidden_participants_partial(max_initially_shown_participants)
      flex_layout do |flex|
        @meeting.invited_or_attended_participants.sort[max_initially_shown_participants..].each do |participant|
          flex.with_row(mt: 1) do
            participant_partial(participant)
          end
        end
      end
    end

    def participant_partial(participant)
      flex_layout(align_items: :center) do |flex|
        flex.with_column do
          render(Users::AvatarComponent.new(user: participant.user,
                                            text_system_attributes: {
                                              font_size: :normal, muted: false
                                            }))
        end
        participant_state_partial(participant, flex)
      end
    end

    def participant_state_partial(participant, flex)
      if participant.attended?
        flex.with_column(ml: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("description_attended").capitalize }
        end
      elsif participant.invited?
        flex.with_column(ml: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) { t("description_invite").capitalize }
        end
      end
    end

    def manage_button_partial
      render(Primer::Beta::Button.new(
               scheme: :link,
               color: :default,
               underline: false,
               font_weight: :bold,
               data: { 'show-dialog-id': "edit-participants-dialog" }
             )) do |button|
        button.with_leading_visual_icon(icon: "person-add")
        t("label_meeting_add_participants")
      end
    end
  end
end
