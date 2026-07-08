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

    # Document event dispatched after a successful move so the frontend can refresh a
    # split view open on the moved work package (see split-view-sync.controller.ts).
    WORK_PACKAGE_MOVED_EVENT = "#{OpTurbo::ComponentStream::DISPATCHED_EVENT_PREFIX}backlogs:work-package-moved".freeze

    before_action :load_work_package, only: %i[menu move_to_sprint_dialog move_to_bucket_dialog move]

    # Deferred ActionMenu items (Primer include-fragment).
    def menu
      render(Backlogs::WorkPackageCardMenuComponent.new(
               project: @project,
               work_package: @work_package,
               open_sprints_exist: target_open_sprints.exists?,
               other_buckets_exist: target_buckets.exists?,
               current_user:
             ),
             layout: false)
    end

    def add_existing_dialog
      target = Target.from_list(params[:list_type], params[:list_id])
      container = target&.container_for(@project)

      if container
        respond_with_dialog Backlogs::AddExistingWorkPackageDialogComponent.new(
          project: @project,
          container:
        )
      elsif target
        render_error_flash_message_via_turbo_stream(message: t(".target_not_found"))
        respond_with_turbo_streams(status: :not_found)
      else
        render_error_flash_message_via_turbo_stream(message: t(".invalid_target"))
        respond_with_turbo_streams(status: :unprocessable_entity)
      end
    end

    def move_to_sprint_dialog
      respond_with_dialog Backlogs::MoveToSprintDialogComponent.new(
        work_package: @work_package,
        project: @project,
        move_action: move_path
      )
    end

    def move_to_bucket_dialog
      respond_with_dialog Backlogs::MoveToBucketDialogComponent.new(
        work_package: @work_package,
        project: @project,
        move_action: move_path
      )
    end

    def add_existing
      work_package = WorkPackage.visible.where(project: @project).find(params.expect(:work_package_id))

      call = ::Backlogs::WorkPackages::UpdateService
        .new(user: current_user, work_package:)
        .call(list_type: params.expect(:list_type), list_id: params[:list_id])

      render_update_turbo_streams(call)
    end

    def move
      source_list = [@work_package.sprint_id, @work_package.backlog_bucket_id]

      call = ::Backlogs::WorkPackages::UpdateService
        .new(user: current_user, work_package: @work_package)
        .call(**move_service_params)

      if optimistic_same_list_move?(call, source_list)
        # A same-list optimistic move (drag or menu) already reordered the row
        # client-side and changes nothing else visible. Skip the frame reload
        # (it would fight that order); still emit the moved event for split-view
        # lock refresh.
        dispatch_event_via_turbo_stream(
          WORK_PACKAGE_MOVED_EVENT,
          detail: { work_package_id: call.result.id }
        )
        return respond_with_turbo_streams(status: call)
      end

      render_update_turbo_streams(call)
    end

    private

    def render_update_turbo_streams(call)
      if call.success?
        reload_frame_via_turbo_stream("backlogs_container")

        # A split view open on the moved work package caches its lock_version. Signal the
        # move so the frontend can refresh that cache and avoid a stale-lock_version conflict
        # on the next edit. Covers both drag-and-drop and the move-to-sprint/bucket dialogs.
        dispatch_event_via_turbo_stream(
          WORK_PACKAGE_MOVED_EVENT,
          detail: { work_package_id: call.result.id }
        )

        render_invisible_after_move_flash(call.result)
      else
        render_error_flash_message_via_turbo_stream(
          message: I18n.t(:notice_unsuccessful_update_with_reason, reason: call.message)
        )
      end

      respond_with_turbo_streams(status: call)
    end

    def render_invisible_after_move_flash(work_package)
      return unless work_package_invisible_after_move?(work_package)

      backlog_name = work_package.sprint&.name ||
        work_package.backlog_bucket&.name ||
        I18n.t(:label_inbox)
      render_flash_message_via_turbo_stream(
        message: I18n.t(:notice_work_package_invisible_after_move, backlog: backlog_name)
      )
    end

    def load_work_package
      @work_packages = WorkPackage.visible.where(project: @project).order_by_position
      @work_package = @work_packages.find(params.expect(:id))
    end

    def move_path
      move_project_backlogs_work_package_path(@project, @work_package, backlog_filter_params)
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

    # After a move the work package might no longer be visible: the page's active
    # sprint/bucket filters (the move dialogs offer every destination, filtered or
    # not) can hide the destination list, and for backlog destinations the project
    # settings for excluded types and statuses apply on top.
    def work_package_invisible_after_move?(work_package)
      return true if work_package_hidden_by_filters?(work_package)
      return false if work_package.sprint_id?

      @project.backlog_excluded_type_ids.include?(work_package.type_id) ||
        @project.done_status_ids.include?(work_package.status_id)
    end

    def work_package_hidden_by_filters?(work_package)
      if work_package.sprint_id?
        backlog_filters.sprint_ids&.exclude?(work_package.sprint_id) || false
      elsif work_package.backlog_bucket_id?
        backlog_filters.bucket_ids&.exclude?(work_package.backlog_bucket_id) || false
      else
        !backlog_filters.show_inbox?
      end
    end

    # Snapshot the source list before the call, not dirty tracking: move_after
    # reloads mid-method, wiping the saved_changes _before_last_save needs.
    def optimistic_same_list_move?(call, source_list)
      optimistic_move? && call.success? &&
        [call.result.sprint_id, call.result.backlog_bucket_id] == source_list
    end

    # Kept out of move_params: the service's keyword args reject it.
    def optimistic_move?
      ActiveModel::Type::Boolean.new.cast(params[:optimistic])
    end

    def move_params
      params.permit(:prev_id, :position, :list_type, :list_id)
    end

    # A blank prev_id (drag or menu move to the top of a list) is kept so the
    # service inserts at the top; nil values (an absent prev_id) are
    # dropped. The service resolves list_type/list_id into the destination list.
    def move_service_params
      move_params.to_h.symbolize_keys.compact
    end
  end
end
