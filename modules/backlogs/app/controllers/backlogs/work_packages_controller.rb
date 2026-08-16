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

    before_action :load_work_package, only: %i[menu move]

    # Deferred ActionMenu items (Primer include-fragment).
    def menu
      render(Backlogs::WorkPackageCardMenuComponent.new(
               project: @project,
               work_package: @work_package,
               sprint_ids: Sprint.assignable(project: @project, user: current_user).order_by_date.ids,
               bucket_ids: BacklogBucket.for_project(@project).order_alphabetically.ids,
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
      work_packages = load_collection_work_packages
      return if performed?

      sprints = destination_availability(work_packages).sprints
      return render_move_collection_error(t(".no_available_destinations")) if sprints.empty?

      respond_with_dialog build_move_to_sprint_dialog(
        work_packages:,
        project: @project,
        sprints:,
        move_action: move_collection_path
      )
    end

    def move_to_bucket_dialog
      work_packages = load_collection_work_packages
      return if performed?

      buckets = destination_availability(work_packages).buckets
      return render_move_collection_error(t(".no_available_destinations")) if buckets.empty?

      respond_with_dialog build_move_to_bucket_dialog(
        work_packages:,
        project: @project,
        buckets:,
        move_action: move_collection_path
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
      source_target = Backlogs::Target.for_work_package(@work_package)
      source_position = @work_package.position

      call = ::Backlogs::WorkPackages::UpdateService
        .new(user: current_user, work_package: @work_package)
        .call(**move_service_params)

      if optimistic_same_list_move?(call, source_target)
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

      if announce_move?(call, source_target, source_position)
        render_move_announcement(call.result)
      end

      render_update_turbo_streams(call)
    end

    def move_collection # rubocop:disable Metrics/AbcSize
      contract = Backlogs::WorkPackages::BatchMoveParamsContract.new(@project, current_user, params: move_collection_params)
      return render_move_collection_error(contract.errors.full_messages.join(" ")) unless contract.valid?

      work_packages = find_collection_work_packages(move_collection_params[:ids])
      return render_move_collection_error(t(".work_packages_not_found")) unless work_packages

      # Snapshot before the call: move_after reloads mid-method and destroys
      # dirty tracking, exactly as the member action's comment explains.
      source_targets = work_packages.to_h { |wp| [wp.id, Backlogs::Target.for_work_package(wp)] }

      call = ::Backlogs::WorkPackages::BatchUpdateService
        .new(user: current_user, work_packages:)
        .call(**collection_move_service_params)

      if optimistic_same_list_batch_move?(call, source_targets)
        dispatch_event_via_turbo_stream(
          WORK_PACKAGE_MOVED_EVENT,
          detail: { work_package_ids: call.result.map(&:id) }
        )
        return respond_with_turbo_streams(status: call)
      end

      render_update_collection_turbo_streams(call)
    end

    private

    def render_update_collection_turbo_streams(call)
      if call.success?
        reload_frame_via_turbo_stream("backlogs_container")
        dispatch_event_via_turbo_stream(
          WORK_PACKAGE_MOVED_EVENT,
          detail: { work_package_ids: call.result.map(&:id) }
        )
        render_invisible_after_move_batch_flash(call.result)
      else
        render_error_flash_message_via_turbo_stream(
          message: I18n.t(:notice_unsuccessful_update_with_reason, reason: batch_failure_reason(call))
        )
      end

      respond_with_turbo_streams(status: call)
    end

    # A member failure is reported with the member: the batch's own message
    # is empty then, and the flash would not say which work package refused.
    def batch_failure_reason(call)
      failed = call.dependent_results.find(&:failure?)
      return call.message unless failed

      work_package = failed.result
      return failed.message unless work_package.is_a?(WorkPackage)

      t("backlogs.work_packages.move_collection.member_failed",
        work_package: work_package.to_fs(:caption), reason: failed.message)
    end

    def optimistic_same_list_batch_move?(call, source_targets)
      return false unless optimistic_move? && call.success? && call.result.any?

      destination = Backlogs::Target.for_work_package(call.result.first)
      call.result.all? { |wp| source_targets[wp.id] == destination } &&
        requested_block_honored?(call.result)
    end

    # The batch form of requested_anchor_honored?: the first member sits where
    # the request anchored it and every further member directly below its
    # predecessor, which is the client's optimistic block.
    def requested_block_honored?(results) # rubocop:disable Metrics/AbcSize
      return false unless move_collection_params.key?(:prev_id)

      # One anchor query; the rest of the block is checked in memory.
      # BatchUpdateService reloads every moved member before returning and
      # the members share one target scope, so adjacent positions prove
      # adjacency. A gap from elsewhere fails this check falsely, degrading
      # to the full frame reload rather than skipping a needed one.
      prev_id = move_collection_params[:prev_id].presence
      first = results.first
      anchor_honored = prev_id ? first.higher_item&.id == prev_id.to_i : first.higher_item.nil?

      anchor_honored && results.each_cons(2).all? { |above, below| below.position == above.position + 1 }
    end

    def collection_move_service_params
      move_collection_params.to_h.symbolize_keys.except(:ids).compact
    end

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

      render_flash_message_via_turbo_stream(
        message: I18n.t(:notice_work_package_invisible_after_move, count: 1, backlog: target_list_name(work_package))
      )
    end

    # A member's own type or status can hide it independently of its
    # list-mates, so the first member cannot answer this for the batch.
    def render_invisible_after_move_batch_flash(results)
      invisible = results.select { |wp| work_package_invisible_after_move?(wp) }
      return if invisible.empty?

      render_flash_message_via_turbo_stream(message: invisible_after_move_batch_message(invisible))
    end

    def invisible_after_move_batch_message(invisible)
      I18n.t(:notice_work_package_invisible_after_move,
             count: invisible.size, backlog: target_list_name(invisible.first))
    end

    # A dialog move (never flagged optimistic) is announced by the server; the
    # optimistic drag and menu paths announce client-side, and the flash
    # covers moves whose result is no longer visible. Persisted no-ops
    # (same target, same position) stay silent.
    def announce_move?(call, source_target, source_position)
      return false if optimistic_move? || call.failure?
      return false if work_package_invisible_after_move?(call.result)

      Backlogs::Target.for_work_package(call.result) != source_target ||
        call.result.position != source_position
    end

    def render_move_announcement(work_package)
      ids = announcement_list_scope(work_package).pluck(:id)
      index = ids.index(work_package.id)
      return if index.nil?

      render_live_region_update_message(
        message: t(
          ".moved_announcement",
          label: work_package.to_fs(:caption),
          list: target_list_name(work_package),
          position: index + 1,
          total: ids.size
        )
      )
    end

    # The scopes the page renders, so the announced position matches what a
    # sighted user sees: sprints are scoped to the project (shared sprints
    # render only the project's items), buckets and the inbox go through the
    # backlog scope with its excluded types and done statuses.
    def announcement_list_scope(work_package)
      if work_package.sprint
        work_package.sprint.work_packages_for(@project)
      else
        WorkPackage.in_backlog_for(project: @project)
          .where(backlog_bucket_id: work_package.backlog_bucket_id)
      end
    end

    def target_list_name(work_package)
      work_package.sprint&.name ||
        work_package.backlog_bucket&.name ||
        I18n.t(:label_inbox)
    end

    def load_work_package
      @work_packages = WorkPackage.visible.where(project: @project).order_by_position
      @work_package = @work_packages.find(params.expect(:id))
    end

    # The dialogs validate the id list alone: they open before a destination
    # is chosen, so BatchMoveParamsContract, which also requires a resolvable
    # target, cannot speak for them. Renders its own error and returns nil,
    # so callers test `performed?`.
    def load_collection_work_packages
      ids = move_collection_params[:ids]

      # Before the lookup: an oversized id list must not reach the database.
      if ids.length > Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE
        return render_move_collection_error(
          t("backlogs.work_packages.move_collection.too_many_work_packages",
            max: Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE)
        )
      end

      if ids.any?(&:blank?) || ids.uniq.length != ids.length
        return render_move_collection_error(t("backlogs.work_packages.move_collection.invalid_ids"))
      end

      find_collection_work_packages(ids) ||
        render_move_collection_error(t("backlogs.work_packages.move_collection.work_packages_not_found"))
    end

    # Every submitted id must resolve to a distinct, visible work package of
    # this project, in the submitted order: silently dropping a member would
    # break the client's optimistic block. Nil when any id does not resolve.
    def find_collection_work_packages(ids)
      found = WorkPackage.visible.where(project: @project, id: ids).index_by { |wp| wp.id.to_s }
      ordered = ids.map { |id| found[id.to_s] }

      ordered.any?(&:nil?) ? nil : ordered
    end

    def render_move_collection_error(reason)
      render_error_flash_message_via_turbo_stream(
        message: I18n.t(:notice_unsuccessful_update_with_reason, reason:)
      )
      respond_with_turbo_streams(status: :unprocessable_entity)
    end

    def destination_availability(work_packages)
      Backlogs::WorkPackages::DestinationAvailability.new(
        project: @project,
        user: current_user,
        work_packages:
      )
    end

    def build_move_to_sprint_dialog(**args)
      Backlogs::MoveToSprintDialogComponent.new(**args)
    end

    def build_move_to_bucket_dialog(**args)
      Backlogs::MoveToBucketDialogComponent.new(**args)
    end

    # params.expect guarantees a present, non-empty array of scalar ids; the
    # optional placement and target fields go through permit instead.
    def move_collection_params
      @move_collection_params ||= begin
        ids = params.expect(ids: [])
        params.permit(:prev_id, :list_type, :list_id).merge(ids:)
      end
    end

    def move_collection_path
      move_project_backlogs_work_packages_path(@project, backlog_filter_params)
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

    # Snapshot the source target before the call, not dirty tracking: move_after
    # reloads mid-method, wiping the saved_changes _before_last_save needs.
    def optimistic_same_list_move?(call, source_target)
      optimistic_move? && call.success? &&
        Backlogs::Target.for_work_package(call.result) == source_target &&
        requested_anchor_honored?(call.result)
    end

    # A nonblank prev_id that has left the target list resolves to nothing, so
    # move_after silently drops the work package at the top, diverging from the
    # optimistic client order. Only skip the reload once the requested anchor
    # is verifiably the persisted one: a nonblank prev_id must be the item
    # right above, and a blank prev_id (top insert) must have nothing above.
    # Requests without an anchor -- a missing prev_id, or a position-based
    # move (nothing sends those optimistically today) -- cannot be verified,
    # so they reconcile via reload.
    def requested_anchor_honored?(work_package)
      return false if move_params[:position].present?
      return false unless move_params.key?(:prev_id)

      prev_id = move_params[:prev_id].presence
      if prev_id
        work_package.higher_item&.id == prev_id.to_i
      else
        work_package.higher_item.nil?
      end
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
