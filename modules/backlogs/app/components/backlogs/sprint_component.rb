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
    include ContainerComponentHelper
    include Redmine::I18n

    attr_reader :sprint, :project, :work_packages, :current_user, :active_sprints, :visible_sprint_ids

    def initialize(sprint:, project:, work_packages: nil, current_user: User.current,
                   active_sprints: nil, visible_sprint_ids: nil)
      super()

      @sprint = sprint
      @project = project
      @current_user = current_user
      @active_sprints = active_sprints
      @visible_sprint_ids = visible_sprint_ids
      @work_packages = work_packages || sprint.work_packages_for(project)
                                              .includes(:status, :type, :assigned_to, :priority, :parent)
    end

    def wrapper_uniq_by
      sprint.id
    end

    private

    def list_type
      Backlogs::Target::SprintId.new(sprint.id).list_type
    end

    def show_start_sprint_action?
      sprint.in_planning? && ::Backlogs::Sprints::StartContract.can_start?(user: current_user, sprint:, project:)
    end

    def show_finish_sprint_action?
      sprint.active? && ::Backlogs::Sprints::StartContract.can_start_or_complete?(user: current_user, sprint:)
    end

    def disable_start_sprint_action?
      sprint.in_planning? && !(sprint.date_range_set? && project_is_allowed_to_activate_sprint?)
    end

    def start_sprint_button_arguments
      base_arguments = { id: dom_target(sprint, :start_button) }

      if disable_start_sprint_action?
        base_arguments.merge(tag: :button, inactive: true, aria: { disabled: true })
      else
        base_arguments.merge(
          tag: :a,
          href: start_project_backlogs_sprint_path(project, sprint, backlog_filter_params),
          data: { turbo_method: :post }
        )
      end
    end

    def finish_sprint_button_arguments
      {
        id: dom_target(sprint, :finish_button),
        tag: :a,
        href: finish_project_backlogs_sprint_path(project, sprint, backlog_filter_params),
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

    # Starting a sprint can be blocked by three independent rules:
    # - `project` is set to receive shared sprints and `sprint` is one of its
    #   own (see StartContract) - unconditionally, regardless of
    #   allow_multiple_active_sprints
    # - the project that actually owns `sprint` already has another active
    #   sprint of its own (the DB-level uniqueness constraint), even if that
    #   other sprint isn't shared with (and is thus invisible to) `project`,
    #   unless the owner allows multiple active sprints
    # - `project` (the project this component is rendered for) already shows
    #   another active sprint on its board - native or shared, as long as it's
    #   visible here, unless `project` allows multiple active sprints
    def project_is_allowed_to_activate_sprint?
      !owned_sprint_blocked_by_receiving? &&
        owner_allows_another_active_sprint? && project_allows_another_active_sprint?
    end

    def owned_sprint_blocked_by_receiving?
      sprint.owned_by?(project) && project.receive_shared_sprints?
    end

    def owner_allows_another_active_sprint?
      sprint.project.allow_multiple_active_sprints? || !sprint_owner_has_another_active_sprint?
    end

    def sprint_owner_has_another_active_sprint?
      @sprint_owner_has_another_active_sprint ||=
        (resolved_active_sprints.select { it.project_id == sprint.project_id }.map(&:id) - [sprint.id]).any?
    end

    def project_allows_another_active_sprint?
      project.allow_multiple_active_sprints? || !project_has_another_active_visible_sprint?
    end

    def project_has_another_active_visible_sprint?
      @project_has_another_active_visible_sprint ||=
        (resolved_active_sprints.select { resolved_visible_sprint_ids.include?(it.id) }.map(&:id) - [sprint.id]).any?
    end

    def start_sprint_disabled_reason
      return unless disable_start_sprint_action?

      if owned_sprint_blocked_by_receiving?
        t(".start_sprint_disabled_reason_receiving_shared_sprints")
      elsif !sprint.date_range_set?
        t(".start_sprint_disabled_reason_missing_dates")
      elsif sprint.owned_by?(project) || project_has_another_active_visible_sprint?
        t(".start_sprint_disabled_reason_active_sprint")
      else
        t(".start_sprint_disabled_reason_shared_sprint")
      end
    end

    # Falls back to querying by hand when not batch-loaded by the caller (e.g.
    # a standalone turbo-stream re-render of a single sprint). Scoped to every
    # project owning a sprint visible on `project`'s board, plus `sprint`'s own
    # owner, so it stays correct for both `sprint_owner_has_another_active_sprint?`
    # (which needs the owner's sprints even if invisible here) and
    # `project_has_another_active_visible_sprint?` (which needs every visible
    # active sprint regardless of who owns it).
    def resolved_active_sprints
      @resolved_active_sprints ||= active_sprints || Sprint.active.where(
        project_id: Sprint.for_project(project).distinct.pluck(:project_id) | [sprint.project_id]
      )
    end

    def resolved_visible_sprint_ids
      @resolved_visible_sprint_ids ||= visible_sprint_ids || Sprint.for_project(project).pluck(:id)
    end

    def show_task_board_link?
      sprint.task_board_for(project).present?
    end

    def show_burndown_link?
      sprint.active? && !OpenProject::FeatureDecisions.sprint_reports_active?
    end

    def show_report_link?
      OpenProject::FeatureDecisions.sprint_reports_active? &&
        user_allowed?(:view_sprints)
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
