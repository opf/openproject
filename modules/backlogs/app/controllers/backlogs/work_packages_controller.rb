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
  class WorkPackagesController < BaseController
    include OpTurbo::ComponentStream

    before_action :load_work_package

    # Deferred ActionMenu items (Primer include-fragment).
    def menu
      render(Backlogs::WorkPackageCardMenuComponent.new(
               project: @project,
               work_package: work_package_with_backlog_neighbours,
               open_sprints_exist: target_open_sprints.exists?,
               other_buckets_exist: target_buckets.exists?,
               current_user:
             ),
             layout: false)
    end

    def move_to_sprint_dialog
      respond_with_dialog Backlogs::MoveToSprintDialogComponent.new(
        work_package: @work_package,
        project: @project,
        move_action: move_project_backlogs_work_package_path(@project, @work_package, backlog_filter_params)
      )
    end

    def move_to_bucket_dialog
      respond_with_dialog Backlogs::MoveToBucketDialogComponent.new(
        work_package: @work_package,
        project: @project,
        move_action: move_project_backlogs_work_package_path(@project, @work_package, backlog_filter_params)
      )
    end

    def move # rubocop:disable Metrics/AbcSize
      call = ::Backlogs::WorkPackages::UpdateService.new(user: current_user, story: @work_package)
                                   .call(**move_params.to_h.symbolize_keys)

      if call.success?
        reload_frame_via_turbo_stream("backlogs_container")

        if work_package_invisible_after_move?(call.result)
          backlog_name = call.result.backlog_bucket&.name || I18n.t(:label_inbox)
          render_flash_message_via_turbo_stream(
            message: I18n.t(:notice_work_package_invisible_after_move, backlog: backlog_name)
          )
        end
      else
        render_error_flash_message_via_turbo_stream(
          message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
        )
      end

      respond_with_turbo_streams(status: call)
    end

    private

    def load_work_package
      @work_packages = WorkPackage.visible.where(project: @project).order_by_position
      @work_package = @work_packages.find(params.expect(:id))
    end

    def move_params
      params.permit(:position, :prev_id, :target_id, :direction)
    end

    def displayed_work_packages
      if @work_package.sprint_id?
        @work_packages.where(sprint_id: @work_package.sprint_id)
      elsif @work_package.backlog_bucket_id?
        @work_packages.merge(@work_package.backlog_bucket.displayed_work_packages)
      else
        @work_packages.merge(WorkPackage.in_inbox_for(project: @project))
      end
    end

    def work_package_with_backlog_neighbours
      displayed_work_packages.with_backlogs_neighbours.find(@work_package.id)
    end

    def target_open_sprints
      Sprint.for_project(@project)
            .visible.not_completed
            .where.not(id: @work_package.sprint_id)
    end

    def target_buckets
      BacklogBucket.where(project: @project)
                   .where.not(id: @work_package.backlog_bucket_id)
    end

    # After a work package is moved to the backlog, it might no longer be visible due to
    # the project settings for excluded types and statuses.
    def work_package_invisible_after_move?(work_package)
      return false if work_package.sprint_id?

      @project.backlog_excluded_type_ids.include?(work_package.type_id) ||
        @project.done_status_ids.include?(work_package.status_id)
    end
  end
end
