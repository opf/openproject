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

module Backlogs
  class SprintFormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include CommonHelper

    FORM_ID = SprintDialogComponent::FORM_ID

    attr_reader :sprint, :project, :current_user, :base_errors

    def initialize(sprint:, project:, current_user: User.current, base_errors: nil)
      super

      @sprint = sprint
      @project = project
      @current_user = current_user
      @base_errors = base_errors
    end

    def shared_sprint?
      sprint.persisted? && !sprint.owned_by?(project)
    end

    def can_edit_sprint?
      return true unless shared_sprint?

      current_user.allowed_in_project?(:create_sprints, sprint.project)
    end

    def can_edit_goal?
      return true unless shared_sprint?

      current_user.allowed_in_project?(:create_sprints, project)
    end

    def banner_scheme
      can_edit_sprint? ? :default : :warning
    end

    def banner_text
      if can_edit_sprint?
        t(".shared_sprint_info_banner")
      else
        t(".shared_sprint_warning_banner")
      end
    end

    def goal
      sprint.goal_for(project) || sprint.goals.build(project:)
    end

    def goal_label
      if shared_sprint?
        I18n.t("backlogs.sprint_form.goal_for_this_project_label", attribute: Sprint.human_attribute_name(:goal))
      else
        Sprint.human_attribute_name(:goal)
      end
    end

    def goal_caption
      I18n.t("backlogs.sprint_form.goal_caption") if shared_sprint?
    end

    private

    def http_verb
      sprint.new_record? ? :post : :put
    end

    def form_url
      if sprint.new_record?
        project_backlogs_sprints_path(project, all_backlogs_params)
      else
        project_backlogs_sprint_path(project, sprint, all_backlogs_params)
      end
    end

    def data_attributes
      {
        controller: "refresh-on-form-changes",
        "refresh-on-form-changes-target": "form",
        "refresh-on-form-changes-turbo-stream-url-value":
          refresh_form_project_backlogs_sprints_path(project, all_backlogs_params)
      }
    end
  end
end
