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

# Moves an ordered batch of work packages into one Backlogs list as a single
# atomic operation. Each member is moved through the existing single-work-
# package UpdateService, always inserting after the previously moved member,
# so the batch lands as one contiguous block in input order.
class Backlogs::WorkPackages::BatchUpdateService
  # Not ActiveRecord::Rollback: the raise happens inside the joined
  # transactions the advisory-lock helper opens, and a joined transaction
  # swallows Rollback without rolling the outer transaction back.
  class BatchFailure < StandardError
    attr_reader :result

    def initialize(result)
      @result = result
      super(result.message)
    end
  end

  # Bounds the recursion in with_ordered_locks (one stack frame per member
  # plus the anchor). Enforced by the controller before it loads the batch.
  MAX_BATCH_SIZE = 500

  attr_reader :user, :work_packages

  def initialize(user:, work_packages:)
    @user = user
    @work_packages = work_packages
  end

  # :explicit (nonblank prev_id), :top (blank prev_id, no anchor) or :append
  # (absent prev_id → the last non-batch member of the target). The append
  # anchor is resolved before any lock is taken so it joins the lock set and
  # can be revalidated under it; a nil anchor means an empty target.
  Placement = Data.define(:mode, :anchor) do
    def initial_prev_id = anchor ? anchor.id.to_s : ""
  end

  def call(list_type: nil, list_id: nil, prev_id: nil) # rubocop:disable Metrics/AbcSize
    target = Backlogs::Target.from_list(list_type, list_id)
    return invalid_target_failure unless target

    # Captured once: placement resolution, anchor revalidation and the cohort
    # check must agree on one project, not re-derive it from a member a
    # concurrent move could have relocated.
    @batch_project_id = work_packages.first.project_id
    @batch_project = work_packages.first.project

    placement = resolve_placement(target, prev_id)
    return placement if placement.is_a?(ServiceResult)

    moved = []

    WorkPackage.transaction do
      with_ordered_locks(lock_entries(placement.anchor)) do
        revalidate_cohort!
        revalidate_target_availability!(target)
        revalidate_anchor!(placement, target)
        current_prev_id = placement.initial_prev_id

        work_packages.each do |work_package|
          # An earlier member's move_after shifts other rows' positions
          # through update_all without touching their loaded Ruby objects,
          # and remove_from_list uses the in-memory position as the threshold
          # it decrements from — a stale read corrupts the positions it
          # writes rather than merely misreporting them.
          work_package.reload
          inner = Backlogs::WorkPackages::UpdateService
            .new(user:, work_package:)
            .call(list_type:, list_id:, prev_id: current_prev_id)

          raise BatchFailure, inner if inner.failure?

          moved << inner.result
          current_prev_id = inner.result.id.to_s
        end

        # WorkPackage#call_after_update_hook builds its context from `self`,
        # so without this a hook consumer observes the interim position a
        # later member's update_all left behind. Still inside the lock and
        # the outer transaction, so the hooks fire against final rows.
        moved.each(&:reload)
      end
    end

    ServiceResult.success(result: moved)
  rescue BatchFailure => e
    e.result
  rescue StandardError => e
    # An operational exception from a later member must not escape as a 500
    # once the rollback has already happened. The message is unlocalized
    # adapter detail, so it is logged rather than shown in the flash.
    Rails.logger.error { "Backlogs batch move failed: #{e.class}: #{e.message}" }
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.unexpected_failure"))
  end

  private

  # Ascending id order, so two overlapping batches request the same lock
  # sequence and neither waits on the other while holding one (the lock
  # helper retries forever). The gem tracks held locks per thread, so the
  # inner services' own acquisitions yield immediately.
  def lock_entries(anchor)
    (work_packages + [anchor]).compact.uniq.sort_by(&:id)
  end

  def with_ordered_locks(entries, index = 0, &)
    return yield if index >= entries.length

    OpenProject::Mutex.with_advisory_lock_transaction(entries[index]) do
      with_ordered_locks(entries, index + 1, &)
    end
  end

  # A nonblank prev_id must be a pure integer id, or Active Record would
  # integer-cast a digit-prefixed string. The anchor is scoped to the batch
  # project because the acts_as_list scope includes project_id: in a shared
  # sprint another project's work package would pass a container-only
  # comparison, yet be unresolvable for move_after, which then silently
  # inserts at the top.
  def resolve_placement(target, prev_id) # rubocop:disable Metrics/AbcSize
    return Placement.new(mode: :append, anchor: last_non_batch_member(target)) if prev_id.nil?
    return Placement.new(mode: :top, anchor: nil) if prev_id.to_s.blank?
    return stale_predecessor_failure unless prev_id.to_s.match?(/\A\d+\z/)
    return stale_predecessor_failure if work_packages.any? { |wp| wp.id == prev_id.to_i }

    anchor = WorkPackage.where(project_id: batch_project_id).find_by(id: prev_id)
    anchor ? Placement.new(mode: :explicit, anchor:) : stale_predecessor_failure
  end

  # A member could have been moved to another project, or deleted, between
  # the controller loading the batch and the locks being taken. A hopped
  # member would move in a different acts_as_list scope, splitting the
  # block, and the chained prev_id would then cross scopes into
  # move_after's silent insert-at-top. One count catches both: it falls
  # short for a hopped or a deleted member.
  def revalidate_cohort!
    matching = WorkPackage.where(id: work_packages.map(&:id), project_id: batch_project_id).count
    return if matching == work_packages.size

    raise BatchFailure, stale_batch_failure
  end

  # Under lock the anchor must still be what placement resolution saw: same
  # project, same list, and for append still the last non-batch member. A
  # concurrently moved anchor would otherwise fall through to move_after's
  # silent insert-at-top.
  def revalidate_anchor!(placement, target) # rubocop:disable Metrics/AbcSize
    anchor = placement.anchor
    return if anchor.nil?

    anchor.reload
    unless anchor.project_id == batch_project_id &&
           Backlogs::Target.for_work_package(anchor) == target
      raise BatchFailure, stale_predecessor_failure
    end

    if placement.mode == :append && last_non_batch_member(target)&.id != anchor.id
      raise BatchFailure, stale_predecessor_failure
    end
  rescue ActiveRecord::RecordNotFound
    raise BatchFailure, stale_predecessor_failure
  end

  # The contract only revalidates a sprint or bucket target when the
  # corresponding column changes, so a same-list reorder never triggers it
  # and a sprint completed after the page loaded stays an accepted
  # destination. Mirrors the contract's own assignable_sprints and
  # backlog_bucket_belongs_to_project checks for every placement mode alike.
  def revalidate_target_availability!(target)
    raise BatchFailure, unavailable_target_failure unless target_available?(target)
  end

  def target_available?(target)
    case target
    in Backlogs::Target::SprintId
      Sprint.assignable(project: batch_project, user:).exists?(id: target.list_id)
    in Backlogs::Target::BucketId
      BacklogBucket.for_project(batch_project).exists?(id: target.list_id)
    in Backlogs::Target::InboxId
      true
    end
  end

  def last_non_batch_member(target)
    WorkPackage
      .where(project_id: batch_project_id, **target.attributes)
      .where.not(id: work_packages.map(&:id))
      .order(:position)
      .last
  end

  def batch_project_id
    @batch_project_id
  end

  def batch_project
    @batch_project
  end

  def invalid_target_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.update_service.invalid_target_type"))
  end

  def stale_predecessor_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor"))
  end

  def stale_batch_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.stale_batch"))
  end

  def unavailable_target_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.unavailable_target"))
  end
end
