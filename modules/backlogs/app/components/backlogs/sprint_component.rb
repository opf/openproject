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
  class SprintComponent < ApplicationComponent
    include Primer::AttributesHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include CommonHelper
    include Redmine::I18n

    attr_reader :sprint, :project, :work_packages, :current_user, :active_sprint_ids

    def initialize(sprint:, project:, work_packages: nil, current_user: User.current,
                   active_sprint_ids: nil)
      super()

      @sprint = sprint
      @project = project
      @current_user = current_user
      @active_sprint_ids = active_sprint_ids
      @work_packages = work_packages || sprint.work_packages_for(project)
                                              .includes(:status, :type, :assigned_to, :priority, :parent)
    end

    def wrapper_uniq_by
      sprint.id
    end

    private

    def show_start_sprint_action?
      sprint.in_planning? && ::Backlogs::Sprints::StartContract.can_start?(user: current_user, sprint:, project:)
    end

    def show_finish_sprint_action?
      sprint.active? && ::Backlogs::Sprints::StartContract.can_start_or_complete?(user: current_user, sprint:)
    end

    def disable_start_sprint_action?
      sprint.in_planning? && (!sprint.date_range_set? || project_has_another_active_sprint?)
    end

    def start_sprint_button_arguments
      base_arguments = { id: dom_target(sprint, :start_button) }

      if disable_start_sprint_action?
        base_arguments.merge(tag: :button, inactive: true, aria: { disabled: true })
      else
        base_arguments.merge(
          tag: :a,
          href: start_project_backlogs_sprint_path(project, sprint),
          data: { turbo_method: :post }
        )
      end
    end

    def finish_sprint_button_arguments
      {
        id: dom_target(sprint, :finish_button),
        tag: :a,
        href: finish_project_backlogs_sprint_path(project, sprint, all_backlogs_params),
        data: { turbo_method: :post }
      }
    end

    def goal_text
      return @goal_text if defined?(@goal_text)

      @goal_text = sprint.goal_text_for(project)
    end

    def sprint_goal_id
      dom_target(sprint, :goal)
    end

    def title_arguments
      return {} if goal_text.blank?

      { aria: { describedby: sprint_goal_id } }
    end

    def story_points_total
      work_packages.filter_map(&:story_points).sum
    end

    def project_has_another_active_sprint?
      (resolved_active_sprint_ids - [sprint.id]).any?
    end

    def start_sprint_disabled_reason
      return unless disable_start_sprint_action?

      if sprint.date_range_set?
        t(".start_sprint_disabled_reason_active_sprint")
      else
        t(".start_sprint_disabled_reason_missing_dates")
      end
    end

    def resolved_active_sprint_ids
      active_sprint_ids || Sprint.for_project(sprint.project).active.pluck(:id)
    end

    def show_task_board_link?
      sprint.task_board_for(project).present?
    end

    def show_burndown_link?
      sprint.active?
    end

    def can_open_edit_dialog?
      if sprint.owned_by?(project)
        user_allowed?(:create_sprints)
      else
        user_allowed?(:create_sprints) || user_allowed?(:create_sprints, project: sprint.project)
      end
    end
  end
end
