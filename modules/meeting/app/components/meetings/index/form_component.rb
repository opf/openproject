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
  class Index::FormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, project:, copy_from: nil, template: false, template_selected_via_dropdown: false)
      super

      @meeting = meeting
      @project = project
      @copy_from = copy_from
      @template = template
      @template_selected_via_dropdown = template_selected_via_dropdown
    end

    private

    def form_controller
      return "meeting_templates" if @template

      if @meeting.is_a?(RecurringMeeting)
        "/recurring_meetings"
      else
        "/meetings"
      end
    end

    def form_method
      if @meeting.new_record?
        :post
      else
        :put
      end
    end

    def form_action
      if @meeting.new_record?
        :create
      else
        :update
      end
    end

    def form_options
      {
        scope: :meeting,
        model: @meeting,
        method: form_method,
        data: {
          turbo: true,
          controller: [
            "show-when-value-selected",
            "show-when-checked",
            @meeting.is_a?(RecurringMeeting) ? "recurring-meetings--form" : nil,
            "meetings--form",
            use_refresh_on_form_changes? ? "refresh-on-form-changes" : nil
          ].compact.join(" "),
          "recurring-meetings--form-persisted-value": @meeting.persisted?,
          "refresh-on-form-changes-target": "form",
          "refresh-on-form-changes-turbo-stream-url-value": fetch_templates_url
        },
        html: { id: "meeting-form" },
        url: { controller: form_controller, action: form_action, project_id: @project }
      }
    end

    def creating_onetime_meeting?
      return false unless EnterpriseToken.allows_to?(:meeting_templates)

      !@meeting.persisted? && !@meeting.is_a?(RecurringMeeting) && !@template
    end

    def no_preselection?
      !@copy_from || @template_selected_via_dropdown
    end

    def show_template_selector?
      return false unless creating_onetime_meeting? && no_preselection?

      if @project.nil?
        # Global context - show if user can see any templates
        globally_visible_templates.any?
      else
        # Project context - only show if the project actually has templates
        available_templates.any?
      end
    end

    def template_selector_disabled?
      effective_project.nil? || available_templates.empty?
    end

    def template_selector_placeholder
      if effective_project.nil?
        I18n.t(:placeholder_meeting_template_select_project_first)
      elsif available_templates.empty?
        I18n.t(:placeholder_meeting_template_no_templates_for_project)
      end
    end

    def use_refresh_on_form_changes?
      creating_onetime_meeting? && no_preselection? && @project.nil?
    end

    def fetch_templates_url
      if @project
        fetch_templates_project_meetings_path(@project)
      else
        fetch_templates_meetings_path
      end
    end

    def available_templates
      @available_templates ||= if effective_project
                                 Meeting.templates_visible_in_project(effective_project)
                               else
                                 Meeting.templates_visible_globally
                               end
    end

    def globally_visible_templates
      @globally_visible_templates ||= Meeting.templates_visible_globally
    end

    def effective_project
      @project || @meeting.project
    end
  end
end
