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

module MeetingSections
  class Backlogs::HeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(backlog:, collapsed:, current_occurrence:)
      super

      @backlog = backlog
      @meeting = backlog.meeting
      @current_occurrence = current_occurrence

      # When a specific collapsed state is needed, collapsed is passed in as either true or false
      # When the collapsed state needs to be determined based on meeting status, collapsed is nil and set via default
      @collapsed = collapsed.nil? ? default_collapsed_state : collapsed
    end

    private

    def default_collapsed_state # rubocop:disable Naming/PredicateMethod
      # For a series backlog, the status of the current occurrence needs to be checked instead of the template
      # For a one-time backlog, @meeting == @current_occurrence
      @current_occurrence.in_progress?
    end

    def description
      if @meeting.recurring?
        I18n.t(:text_series_backlog)
      else
        I18n.t(:text_agenda_backlog)
      end
    end

    def edit_enabled?
      !@meeting.closed? && User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    def clear_action_item(menu)
      menu.with_item(
        label: I18n.t(:label_backlog_clear),
        href: clear_backlog_dialog_project_meeting_sections_path(@meeting.project,
                                                                 @meeting,
                                                                 current_occurrence: @current_occurrence),
        scheme: :danger,
        tag: :a,
        content_arguments: {
          data: { controller: "async-dialog" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def add_agenda_item_action(menu)
      menu.with_item(
        label: t("label_agenda_item_add", count: 1),
        href: new_project_meeting_agenda_item_path(@meeting.project,
                                                   @meeting,
                                                   type: "simple",
                                                   meeting_section_id: @backlog.id,
                                                   current_occurrence: @current_occurrence),
        content_arguments: {
          data: { "turbo-stream": true, "test-selector": "meeting-backlog-add-agenda-item-from-menu" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :plus)
      end
    end

    def add_work_package_action(menu)
      menu.with_item(
        label: t("label_agenda_item_work_package_add", count: 1),
        href: new_project_meeting_agenda_item_path(@meeting.project,
                                                   @meeting,
                                                   type: "work_package",
                                                   meeting_section_id: @backlog.id,
                                                   current_occurrence: @current_occurrence),
        content_arguments: {
          data: { "turbo-stream": true, "test-selector": "meeting-backlog-add-work-package-from-menu" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :plus)
      end
    end
  end
end
