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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Meetings
  class SidePanel::StatusButtonComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, size: :medium)
      super

      @meeting = meeting
      @project = meeting.project
      @size = size
    end

    def call
      render(
        OpPrimer::StatusButtonComponent.new(
          current_status: current_status,
          items: [open_status, in_progress_status, closed_status],
          readonly: !edit_enabled? || @meeting.draft?,
          disabled: !edit_enabled? || @meeting.draft?,
          button_arguments: {
            title: t("label_meeting_state"),
            size: @size
          },
          menu_arguments: { size: :small }
        )
      )
    end

    private

    def edit_enabled?
      User.current.allowed_in_project?(:manage_agendas, @project) ||
        User.current.allowed_in_project?(:edit_meetings, @project)
    end

    def current_status
      case @meeting.state
      when "draft"
        draft_status
      when "open"
        open_status
      when "in_progress"
        in_progress_status
      when "closed"
        closed_status
      end
    end

    def draft_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_draft"),
                                       color_ref: Meetings::Statuses::DRAFT.id,
                                       color_namespace: :meeting_status,
                                       icon: :"issue-draft",
                                       tag: :a)
    end

    def open_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_open"),
                                       color_ref: Meetings::Statuses::OPEN.id,
                                       color_namespace: :meeting_status,
                                       icon: :"issue-opened",
                                       tag: :a,
                                       href: href("open"),
                                       description: t("text_meeting_open_dropdown_description"),
                                       content_arguments: {
                                         data: data_attributes(href("open"))
                                       })
    end

    def in_progress_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_in_progress"),
                                       color_ref: Meetings::Statuses::IN_PROGRESS.id,
                                       color_namespace: :meeting_status,
                                       icon: :play,
                                       tag: :a,
                                       href: href("in_progress"),
                                       description: t("text_meeting_in_progress_dropdown_description"),
                                       content_arguments: {
                                         data: data_attributes(href("in_progress"))
                                       })
    end

    def closed_status
      OpPrimer::StatusButtonOption.new(name: t("label_meeting_state_closed"),
                                       color_ref: Meetings::Statuses::CLOSED.id,
                                       color_namespace: :meeting_status,
                                       icon: :"issue-closed",
                                       tag: :a,
                                       href: href("closed"),
                                       description: t("text_meeting_closed_dropdown_description"),
                                       content_arguments: {
                                         data: data_attributes(href("closed"))
                                       })
    end

    def href(state)
      change_state_project_meeting_path(@project, @meeting, state: state)
    end

    def data_attributes(href)
      {
        action: "click->meetings--submit#intercept",
        href: href
      }
    end
  end
end
