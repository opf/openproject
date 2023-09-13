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
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:)
      super

      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
    end

    def call
      flex_layout do |flex|
        flex.with_row do
          first_row_partial
        end
        flex.with_row(mt: edit_enabled? ? 1 : 2, pl: 4) do
          second_row_partial
        end
      end
    end

    private

    def drag_and_drop_enabled?
      @meeting.open? && User.current.allowed_to?(:create_meeting_agendas, @meeting.project)
    end

    def show_time_slot?
      false
    end

    def edit_enabled?
      @meeting.open? && User.current.allowed_to?(:create_meeting_agendas, @meeting.project)
    end

    def first_row_partial
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column(flex: 1) do
          left_column_partial
        end
        flex.with_column do
          right_column_partial
        end
      end
    end

    def second_row_partial
      if @meeting_agenda_item.description.present?
        description_partial
      end
    end

    def left_column_partial
      flex_layout(align_items: :flex_start) do |flex|
        flex.with_column(mx: 1, pt: 2) do
          if drag_and_drop_enabled?
            drag_handler_partial
          end
        end
        flex.with_column(flex: 1, mt: 2, pl: drag_and_drop_enabled? ? 0 : 3) do
          if @meeting_agenda_item.visible_work_package?
            work_package_title_partial
          elsif @meeting_agenda_item.linked_work_package?
            work_package_undisclosed_partial
          else
            title_partial
          end
        end
      end
    end

    def right_column_partial
      flex_layout(align_items: :center, mt: edit_enabled? ? 1 : 2) do |flex|
        if show_time_slot?
          flex.with_column(pr: 2) do
            time_slot_partial
          end
        end
        flex.with_column(mr: 2) do
          render(Users::AvatarComponent.new(user: @meeting_agenda_item.author, text_system_attributes: { muted: true }))
        end
        flex.with_column do
          actions_partial if edit_enabled?
        end
      end
    end

    def drag_handler_partial
      render(Primer::Beta::Octicon.new(
               color: :subtle,
               classes: "handle",
               style: "cursor: move;",
               size: :small,
               icon: :grabber
             ))
    end

    def work_package_title_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          work_package_link_partial
        end
        flex.with_column(mr: 2) do
          work_package_type_and_id_partial
        end
        flex.with_column(mr: 2) do
          work_package_status_partial
        end
        flex.with_column do
          duration_partial
        end
      end
    end

    def work_package_undisclosed_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) do
            I18n.t(:label_agenda_item_undisclosed_wp, id: @meeting_agenda_item.work_package_id)
          end
        end
        flex.with_column do
          duration_partial
        end
      end
    end

    def work_package_link_partial
      render(Primer::Beta::Link.new(href: work_package_path(@meeting_agenda_item.work_package), underline: false,
                                    font_size: :normal, font_weight: :bold, target: "_blank")) do
        render(Primer::Beta::Truncate.new) do |component|
          component.with_item(max_width: 300, expandable: true) do
            @meeting_agenda_item.work_package.subject
          end
        end
      end
    end

    def work_package_type_and_id_partial
      render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) do
        "#{@meeting_agenda_item.work_package.type.name} ##{@meeting_agenda_item.work_package.id}"
      end
    end

    def work_package_status_partial
      render(Primer::Beta::Label.new(font_weight: :bold)) do
        @meeting_agenda_item.work_package.status.name
      end
    end

    def duration_partial
      render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) do
        "#{@meeting_agenda_item.duration_in_minutes || 0} min"
      end
    end

    def title_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) do
          render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold, test_selector: 'op-meeting-agenda-title')) do
            render(Primer::Beta::Truncate.new) do |component|
              component.with_item(max_width: 300, expandable: true) { @meeting_agenda_item.title }
            end
          end
        end
        flex.with_column do
          duration_partial
        end
      end
    end

    def description_partial
      render(Primer::Box.new(color: :subtle)) do
        ::OpenProject::TextFormatting::Renderer.format_text(@meeting_agenda_item.description)
      end
    end

    def time_slot_partial
      render(Primer::Beta::Text.new(font_size: :normal, color: :subtle)) do
        [
          @meeting_agenda_item.start_time.strftime("%H:%M"),
          "-",
          @meeting_agenda_item.end_time.strftime("%H:%M"),
          "(#{@meeting_agenda_item.duration_in_minutes || 0} min)"
        ].join(" ")
      end
    end

    def actions_partial
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", 'aria-label': t("label_agenda_item_actions"), scheme: :invisible, test_selector: 'op-meeting-agenda-actions')
        edit_action_item(menu)
        move_actions(menu)
        delete_action_item(menu)
      end
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
  end
end
