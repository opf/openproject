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

module Meetings
  class HeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include Primer::FetchOrFallbackHelper
    include Redmine::I18n

    STATE_DEFAULT = :show
    STATE_EDIT = :edit
    STATE_OPTIONS = [STATE_DEFAULT, STATE_EDIT].freeze

    def initialize(meeting:, state: STATE_DEFAULT)
      super

      @meeting = meeting
      @series = meeting.recurring_meeting
      @project = meeting.project
      @state = fetch_or_fallback(STATE_OPTIONS, state)
    end

    def page_header_data_attributes
      {
        poll_for_changes_target: "reference",
        reference_value: @meeting.changed_hash,
        controller: "editable-page-header-title",
        "editable-page-header-title-input-id-value": "meeting_title"
      }
    end

    # Define the interval so it can be overriden through tests
    def check_for_updates_interval
      10_000
    end

    def ics_download_path
      if @series
        download_ics_project_recurring_meeting_path(@series.project, @series, occurrence_id: @meeting.id)
      else
        download_ics_project_meeting_path(@meeting.project, @meeting)
      end
    end

    def can_start_presentation?
      !@meeting.template? &&
        !@meeting.draft? &&
        @meeting.agenda_items.any?
    end

    private

    def delete_enabled?
      !@meeting.series_template? && User.current.allowed_in_project?(:delete_meetings, @meeting.project)
    end

    def copy_enabled?
      User.current.allowed_in_project?(:create_meetings, @meeting.project)
    end

    def finish_setup_enabled?
      @meeting.draft? &&
        !@meeting.onetime_template? &&
        User.current.allowed_in_project?(:edit_meetings, @meeting.project)
    end

    def delete_series_enabled?
      @meeting.series_template? && @meeting.draft? && User.current.allowed_in_project?(:delete_meetings, @project)
    end

    def create_from_template_enabled?
      @meeting.onetime_template? &&
        User.current.allowed_in_project?(:create_meetings, @meeting.project) &&
        EnterpriseToken.allows_to?(:meeting_templates)
    end

    def create_from_template_button_params
      {
        tag: :a,
        scheme: :secondary,
        mobile_label: I18n.t("label_meeting_create_from_template"),
        mobile_icon: :plus,
        size: :medium,
        href: new_dialog_project_meetings_path(@project, template_id: @meeting.id),
        id: "create-meeting-from-template",
        data: { turbo_stream: true },
        aria: { label: I18n.t("label_meeting_create_from_template") }
      }
    end

    def action_button_params
      {
        tag: :button,
        scheme: :primary,
        mobile_label: action_button_label,
        mobile_icon: :check,
        size: :medium,
        id: "open-meeting-button",
        data: {
          action: "click->meetings--submit#intercept",
          href: action_button_href,
          method: "GET"
        }
      }
    end

    def action_button_label
      @meeting.recurring? ? I18n.t("recurring_meeting.template.button_finalize") : I18n.t("label_meeting_open_action")
    end

    def action_button_href
      exit_draft_mode_dialog_project_meeting_path(@project, @meeting)
    end

    def send_emails?
      !@meeting.closed? &&
        @meeting.notify? &&
        User.current.allowed_in_project?(:send_meeting_invites_and_outcomes, @meeting.project)
    end

    def breadcrumb_items
      [
        ({ href: project_overview_path(@project.id), text: @project.name } if @project.present?),
        { href: @project.present? ? project_meetings_path(@project.id) : meetings_path,
          text: I18n.t(:label_meeting_plural) },
        meeting_type_element,
        meeting_element
      ].compact
    end

    def meeting_element
      if @meeting.onetime_template?
        @meeting.title
      elsif @meeting.series_template?
        I18n.t(:label_template)
      elsif @series.present?
        format_date(@meeting.start_time)
      else
        @meeting.title
      end
    end

    def meeting_type_element
      if @series.present?
        { href: project_recurring_meeting_path(@series.project, @series), text: @series.title }
      elsif @meeting.onetime_template?
        { href: url_for({ controller: "meeting_templates", action: :index, project_id: @project }),
          text: I18n.t(:label_meeting_templates) }
      end
    end

    def delete_label
      if @series.present?
        I18n.t("label_recurring_meeting_cancel")
      elsif @meeting.onetime_template?
        I18n.t("label_meeting_template_delete")
      else
        I18n.t("label_meeting_delete")
      end
    end

    def copy_label
      if @series.present?
        I18n.t("label_recurring_meeting_duplicate")
      else
        I18n.t("button_duplicate")
      end
    end

    def edit_label
      if @meeting.onetime_template?
        I18n.t("label_meeting_template_edit")
      else
        I18n.t("label_meeting_edit_title")
      end
    end
  end
end
