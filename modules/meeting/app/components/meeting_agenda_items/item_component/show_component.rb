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
  class ItemComponent::ShowComponent < ApplicationComponent
    include ApplicationHelper
    include AvatarHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:)
      super

      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    private

    def drag_and_drop_enabled?
      @meeting.open? && User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    def dropdown_menu_enabled?
      @meeting.open? && User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    def edit_enabled?
      @meeting.open? && !@meeting_agenda_item.deleted_work_package?
    end

    def edit_action_item(menu)
      menu.with_item(label: t("label_edit"),
                     href: edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
                     content_arguments: {
                       data: { 'turbo-stream': true }
                     }) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def move_actions(menu)
      move_action_item(menu, :highest, t("label_agenda_item_move_to_top"), "move-to-top") unless @meeting_agenda_item.first?
      move_action_item(menu, :higher, t("label_agenda_item_move_up"), "chevron-up") unless @meeting_agenda_item.first?
      move_action_item(menu, :lower, t("label_agenda_item_move_down"), "chevron-down") unless @meeting_agenda_item.last?
      move_action_item(menu, :lowest, t("label_agenda_item_move_to_bottom"), "move-to-bottom") unless @meeting_agenda_item.last?
    end

    def delete_action_item(menu)
      menu.with_item(label: t("text_destroy"),
                     scheme: :danger,
                     href: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
                     form_arguments: {
                       method: :delete, data: { confirm: t("text_are_you_sure"), 'turbo-stream': true }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def move_action_item(menu, move_to, label_text, icon)
      menu.with_item(label: label_text,
                     href: move_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item,
                                                         move_to:),
                     form_arguments: {
                       method: :put, data: { 'turbo-stream': true }
                     }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def duration_color_scheme
      if @meeting.end_time < @meeting_agenda_item.end_time
        :danger
      else
        :subtle
      end
    end
  end
end
