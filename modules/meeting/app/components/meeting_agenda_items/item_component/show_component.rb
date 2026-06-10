# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
    include Redmine::I18n

    def initialize(meeting_agenda_item:,
                   first_and_last: [],
                   current_occurrence: nil,
                   presentation_mode: false)
      super

      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
      @series = @meeting.recurring_meeting
      @first_and_last = first_and_last
      @current_occurrence = current_occurrence
      @presentation_mode = presentation_mode
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    private

    def presentation_mode?
      @presentation_mode
    end

    def drag_and_drop_enabled?
      return false if presentation_mode?

      !@meeting.closed? && User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    def can_manage_agendas?
      User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    def add_outcome_action?
      editable? &&
        @meeting.in_progress? &&
        !@meeting_agenda_item.in_backlog? &&
        User.current.allowed_in_project?(:manage_outcomes, @meeting.project)
    end

    def add_note_action?
      editable? && @meeting_agenda_item.notes.blank?
    end

    def convert_to_work_package_action?
      editable? &&
        @meeting_agenda_item.simple? &&
        User.current.allowed_in_project?(:add_work_packages, @meeting.project)
    end

    def first?
      @first ||=
        if @first_and_last.first
          @first_and_last.first == @meeting_agenda_item
        else
          @meeting_agenda_item.first?
        end
    end

    def last?
      @last ||=
        if @first_and_last.last
          @first_and_last.last == @meeting_agenda_item
        else
          @meeting_agenda_item.last?
        end
    end

    def meeting_closed?
      !@meeting.open?
    end

    def recurring_meeting?
      @series.present?
    end

    def edit_action_item(menu)
      return unless editable?

      menu.with_item(label: t("label_edit"),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: edit_project_meeting_agenda_item_path(
                         @meeting_agenda_item.meeting.project,
                         @meeting_agenda_item.meeting,
                         @meeting_agenda_item,
                         presentation_mode: @presentation_mode,
                         current_occurrence: @current_occurrence
                       ),
                       method: "GET"
                     } }) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def convert_to_work_package_action_item(menu)
      menu.with_item(label: t("label_agenda_item_convert_to_work_package"),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: convert_to_work_package_dialog_project_meeting_agenda_item_path(
                         @meeting.project,
                         @meeting,
                         @meeting_agenda_item
                       ),
                       method: "GET"
                     } }) do |item|
        item.with_leading_visual_icon(icon: :"package-dependents")
      end
    end

    def add_note_action_item(menu)
      menu.with_item(label: t("label_agenda_item_add_notes"),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: edit_project_meeting_agenda_item_path(
                         @meeting_agenda_item.meeting.project,
                         @meeting_agenda_item.meeting,
                         @meeting_agenda_item,
                         display_notes_input: true,
                         current_occurrence: @current_occurrence
                       ),
                       method: "GET"
                     } }) do |item|
        item.with_leading_visual_icon(icon: :note)
      end
    end

    def add_outcome_action_items(menu)
      menu.with_sub_menu_item(label: t("label_agenda_item_add_outcome")) do |submenu|
        submenu.with_leading_visual_icon(icon: :plus)

        with_item_group(submenu) do
          add_write_outcome_item(submenu)
          add_existing_work_package_item(submenu)
          add_new_work_package_item(submenu)
        end
      end
    end

    def add_write_outcome_item(submenu)
      submenu.with_item(label: t("label_write_outcome"),
                        tag: :button,
                        content_arguments: outcome_action_data(
                          new_project_meeting_agenda_item_outcome_path(
                            @meeting_agenda_item.meeting.project,
                            @meeting_agenda_item.meeting,
                            @meeting_agenda_item,
                            kind: :information,
                            current_occurrence: @current_occurrence
                          )
                        ))
    end

    def add_existing_work_package_item(submenu)
      submenu.with_item(label: t("label_existing_work_package"),
                        tag: :button,
                        content_arguments: outcome_action_data(
                          new_project_meeting_agenda_item_outcome_path(
                            @meeting.project,
                            @meeting,
                            @meeting_agenda_item,
                            kind: :work_package,
                            current_occurrence: @current_occurrence
                          )
                        ))
    end

    def add_new_work_package_item(submenu)
      return unless User.current.allowed_in_project?(:add_work_packages, @meeting.project)

      submenu.with_item(label: t("label_work_package_new"),
                        tag: :button,
                        content_arguments: outcome_action_data(
                          create_work_package_dialog_project_meeting_agenda_item_outcomes_path(
                            @meeting.project,
                            @meeting,
                            @meeting_agenda_item
                          )
                        ))
    end

    def outcome_action_data(href)
      { data: { action: "click->meetings--submit#intercept", href:, method: "GET" } }
    end

    def copy_action_item(menu)
      url = project_meeting_url(@meeting.project, @meeting, anchor: "meeting-agenda-item-#{@meeting_agenda_item.id}")
      menu.with_item(label: t("meeting.copy.to_clipboard"),
                     tag: :"clipboard-copy",
                     content_arguments: { value: url }) do |item|
        item.with_leading_visual_icon(icon: :copy)
      end
    end

    def move_to_next_meeting_action_item(menu)
      next_meeting_action_item(
        menu,
        label: t(:label_agenda_item_move_to_next),
        action: :move_to_next,
        icon: "arrow-right"
      )
    end

    def duplicate_in_next_meeting_action_item(menu)
      next_meeting_action_item(
        menu,
        label: t(:label_agenda_item_duplicate_in_next),
        action: :duplicate_in_next,
        icon: :duplicate
      )
    end

    def next_meeting_action_item(menu, label:, action:, icon:)
      return unless has_next_occurrence?

      result = @series.first_available_occurrence(from_time: next_occurrence_from_time)
      return if result.nil?

      next_date = result[:occurrence]
      skipped_cancelled = result[:skipped_cancelled]
      skipped_closed = result[:skipped_closed]

      menu.with_item(
        label:,
        tag: :button,
        content_arguments: { data: {
          action: "click->meetings--submit#intercept",
          href: path_for_next_button(action:, next_date:, skipped_cancelled:, skipped_closed:),
          method: "GET"
        } }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def has_next_occurrence?
      return false unless editable?
      return false if in_template?
      return false if @series.nil?

      next_date = @series.next_occurrence(from_time: next_occurrence_from_time)
      next_date.present?
    end

    ##
    # Find the next occurrence that we can move an item to.
    # Even if meeting.start_time is in the past, its canonical reccurrence_start_time might be in the future.
    # (when the meeting has been moved earlier than it recurrence time).
    #
    # In order to find the next valid slot, we need to skip:
    # - at least past the recurrence_start_time (which may be sooner or later than the start_time)
    # - the actual scheduled start_time of the meeting
    # - the current time, to ensure we don't move to a past meeting.
    def next_occurrence_from_time
      [@meeting.recurrence_start_time, @meeting.start_time, Time.current].compact.max
    end

    def has_move_actions?
      return false unless editable?

      return true unless first? && last?
      return true if many_sections?
      return true if !in_template? || in_backlog?
      return true if has_next_occurrence?

      false
    end

    def move_actions(menu)
      return unless editable?

      move_action_item(menu, :highest, t("label_agenda_item_move_to_top"), "move-to-top") unless first?
      move_action_item(menu, :higher, t("label_agenda_item_move_up"), "chevron-up") unless first?
      move_action_item(menu, :lower, t("label_agenda_item_move_down"), "chevron-down") unless last?
      move_action_item(menu, :lowest, t("label_agenda_item_move_to_bottom"), "move-to-bottom") unless last?
    end

    def delete_action_item(menu)
      return unless editable?
      return if presentation_mode?

      label = @meeting_agenda_item.work_package_id.present? ? wp_agenda_item_delete_label : t(:text_destroy)
      menu.with_item(label:,
                     scheme: :danger,
                     href: project_meeting_agenda_item_path(
                       @meeting.project,
                       @meeting,
                       @meeting_agenda_item,
                       current_occurrence: @current_occurrence
                     ),
                     form_arguments: {
                       method: :delete, data: { turbo_confirm: t(:text_are_you_sure), "turbo-stream": true }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def wp_agenda_item_delete_label
      @meeting_agenda_item.in_backlog? ? t(:label_agenda_item_remove_from_backlog) : t(:label_agenda_item_remove_from_agenda)
    end

    def move_action_item(menu, move_to, label_text, icon)
      menu.with_item(label: label_text,
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: move_project_meeting_agenda_item_path(
                         @meeting.project,
                         @meeting,
                         @meeting_agenda_item,
                         move_to:,
                         current_occurrence: @current_occurrence
                       )
                     } }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def move_to_backlog_action_item(menu)
      return unless editable?

      menu.with_item(label: I18n.t(:label_agenda_item_move_to_backlog),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: drop_project_meeting_agenda_item_path(
                         @meeting.project,
                         @meeting,
                         @meeting_agenda_item,
                         type: :to_backlog,
                         current_occurrence: @current_occurrence
                       )
                     } }) do |item|
        item.with_leading_visual_icon(icon: "discussion-outdated")
      end
    end

    def move_to_current_meeting_action_item(menu)
      return unless editable?
      return if many_sections?

      menu.with_item(label: I18n.t(:label_agenda_item_move_to_current_meeting),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: drop_project_meeting_agenda_item_path(
                         @meeting.project,
                         @meeting,
                         @meeting_agenda_item,
                         type: :to_current,
                         current_occurrence: @current_occurrence
                       )
                     } }) do |item|
        item.with_leading_visual_icon(icon: "cross-reference")
      end
    end

    def move_to_section_action_item(menu)
      return unless editable?
      return unless many_sections?

      menu.with_item(label: I18n.t(:label_agenda_item_move_to_section),
                     tag: :button,
                     content_arguments: { data: {
                       action: "click->meetings--submit#intercept",
                       href: move_to_section_dialog_project_meeting_agenda_item_path(
                         @meeting.project,
                         @meeting,
                         @meeting_agenda_item,
                         current_occurrence: @current_occurrence
                       )
                     } }) do |item|
        item.with_leading_visual_icon(icon: "op-move")
      end
    end

    def notes_classes
      if @meeting.open?
        "op-uc-container override"
      else
        "op-uc-container override muted-color"
      end
    end

    def move_to_next_meeting_enabled?
      return false unless editable?

      @meeting.recurring? && @meeting.recurring_meeting&.next_occurrence.present? && !in_template?
    end

    def in_backlog?
      @meeting_agenda_item.meeting_section.backlog?
    end

    def in_template?
      @meeting.templated?
    end

    def move_to_different_section_or_meeting_action_added?
      return false unless editable?

      !in_template? || in_backlog? || move_to_next_meeting_enabled?
    end

    def editable?
      @editable ||= @meeting_agenda_item.editable? && can_manage_agendas?
    end

    def in_section?
      true
    end

    def many_sections?
      if @meeting_agenda_item.in_backlog? && @current_occurrence.present?
        @current_occurrence.sections.many?
      else
        @meeting.sections.many?
      end
    end

    def path_for_next_button(action:, next_date:, skipped_cancelled:, skipped_closed:)
      skipped_cancelled_iso = skipped_cancelled.map(&:iso8601) if skipped_cancelled.present?
      skipped_closed_iso = skipped_closed.map(&:iso8601) if skipped_closed.present?

      case action
      when :move_to_next
        move_to_next_dialog_project_meeting_agenda_item_path(@meeting.project,
                                                             @meeting,
                                                             @meeting_agenda_item,
                                                             datetime: next_date.iso8601,
                                                             skipped_cancelled: skipped_cancelled_iso,
                                                             skipped_closed: skipped_closed_iso)
      when :duplicate_in_next
        duplicate_in_next_dialog_project_meeting_agenda_item_path(@meeting.project,
                                                                  @meeting,
                                                                  @meeting_agenda_item,
                                                                  datetime: next_date.iso8601,
                                                                  skipped_cancelled: skipped_cancelled_iso,
                                                                  skipped_closed: skipped_closed_iso)
      end
    end
  end
end
