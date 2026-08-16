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
#
# Call it outside a transaction. The advisory locks it takes are
# transaction-scoped (`pg_advisory_xact_lock`), and Postgres binds those to
# the top-level transaction, not to the savepoint below: a caller that wraps
# this in its own transaction would hold every container's lock until that
# outer transaction ends, serializing unrelated moves behind it.
class Backlogs::WorkPackages::BatchUpdateService
  # Enforced by the controller before it loads the batch and by the service
  # itself for every other caller.
  MAX_BATCH_SIZE = 500

  attr_reader :user, :work_packages

  def initialize(user:, work_packages:)
    @user = user
    @work_packages = work_packages
  end

  # :explicit (nonblank prev_id), :top (blank prev_id, no anchor) or :append
  # (absent prev_id → the last non-batch member of the target, read under the
  # placement lock so it joins the lock set and can be revalidated); a nil
  # anchor means an empty target.
  Placement = Data.define(:mode, :anchor) do
    def initial_prev_id = anchor ? anchor.id.to_s : ""
  end

  def call(list_type: nil, list_id: nil, prev_id: nil) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    return empty_batch_failure if work_packages.empty?

    contract = Backlogs::WorkPackages::BatchMoveParamsContract.new(
      work_packages.first.project,
      user,
      params: { ids: work_packages.map(&:id), list_type:, list_id:, prev_id: }
    )
    return ServiceResult.failure(errors: contract.errors) unless contract.valid?

    target = Backlogs::Target.from_list(list_type, list_id)
    return mixed_projects_failure unless work_packages.map(&:project_id).uniq.one?

    # Captured once: placement resolution, anchor revalidation and the cohort
    # check must agree on one project, not re-derive it from a member a
    # concurrent move could have relocated.
    @batch_project_id = work_packages.first.project_id
    @batch_project = work_packages.first.project
    @batch_source_targets = work_packages.to_h do |work_package|
      [work_package.id, Backlogs::Target.for_work_package(work_package)]
    end

    call = nil
    # Its own savepoint: joined into an enclosing transaction, the rollback
    # below would be swallowed and half the batch would commit.
    WorkPackage.transaction(requires_new: true) do
      call = move_batch(target, prev_id, list_type:, list_id:)
      raise ActiveRecord::Rollback if call.failure?
    end
    call
  rescue StandardError => e
    # An operational exception from a later member must not escape as a 500
    # once the rollback has already happened. The message is unlocalized
    # adapter detail, so it is logged rather than shown in the flash.
    Rails.logger.error { "Backlogs batch move failed: #{e.class}: #{e.message}" }
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.unexpected_failure"))
  end

  private

  def move_batch(target, prev_id, list_type:, list_id:)
    destination = raw_destination(target)
    acquire_ordered_locks(ordered_lifecycle_records(destination))
    acquire_placement_serialization_lock(target, prev_id)
    placement = resolve_placement(target, prev_id)
    return placement if placement.is_a?(ServiceResult)

    acquire_ordered_locks(lock_entries(placement.anchor))
    return stale_batch_failure unless cohort_intact?

    lock_destination_row!(destination)
    destination_failure = revalidate_destination(target)
    return destination_failure if destination_failure

    anchor_failure = revalidate_anchor(placement, target)
    return anchor_failure if anchor_failure

    move_members(placement, list_type:, list_id:)
  end

  def move_members(placement, list_type:, list_id:) # rubocop:disable Metrics/AbcSize
    call = ServiceResult.success(result: [])
    current_prev_id = placement.initial_prev_id

    work_packages.each do |work_package|
      # An earlier member's move_after shifts other rows' positions through
      # update_all without touching their loaded Ruby objects, and
      # remove_from_list uses the in-memory position as the threshold it
      # decrements from — a stale read corrupts the positions it writes.
      work_package.reload
      inner = Backlogs::WorkPackages::UpdateService
        .new(user:, work_package:)
        .call(list_type:, list_id:, prev_id: current_prev_id)
      call.add_dependent!(inner)
      return call if inner.failure?

      call.result << inner.result
      current_prev_id = inner.result.id.to_s
    end

    # WorkPackage#call_after_update_hook builds its context from `self`, so
    # without this a hook consumer observes the interim position a later
    # member's update_all left behind. Still inside the outer transaction,
    # so the hooks fire against final rows.
    call.result.each(&:reload)
    call
  end

  # Sprint lifecycle services serialize on the Sprint model mutex before
  # enumerating and moving their work packages, so a batch has to join every
  # source lifecycle as well as the target's: locking only the target lets a
  # batch move a member out after FinishService has enumerated it. Sorted by
  # class and id, so two batches with inverse source/target pairs cannot
  # deadlock.
  def ordered_lifecycle_records(destination)
    source_records = @batch_source_targets.values.uniq.filter_map { |target| raw_destination(target) }

    (source_records + [destination])
      .compact
      .uniq { |record| lifecycle_lock_identity(record) }
      .sort_by { |record| lifecycle_lock_identity(record) }
  end

  def lifecycle_lock_identity(record)
    [record.class.name, record.id]
  end

  # Unanchored placement depends on target-relative state no row can carry:
  # in an empty Inbox two batches would otherwise both commit positions 1..N.
  # Explicit placement needs none of this, being serialized by its anchor's
  # own lock.
  def acquire_placement_serialization_lock(target, prev_id)
    return if prev_id.present?

    suffix = ["backlogs_batch_update_destination", target.list_type, target.list_id].compact.join("_")
    # rubocop:disable Lint/EmptyBlock -- the lock outlives the block; see acquire_ordered_locks
    OpenProject::Mutex.with_advisory_lock_transaction(batch_project, suffix) {}
    # rubocop:enable Lint/EmptyBlock
  end

  # Ascending id order, so two overlapping batches request the same lock
  # sequence and neither waits on the other while holding one.
  def lock_entries(anchor)
    (work_packages + [anchor]).compact.uniq.sort_by(&:id)
  end

  # Transaction-scoped locks outlive their block until the enclosing
  # transaction ends, so each one is taken with an empty block in one flat
  # sequence. The gem's per-thread lock stack forgets the lock at block exit,
  # so the inner services re-request theirs; Postgres grants a lock the
  # session already holds without waiting.
  def acquire_ordered_locks(entries)
    entries.each do |entry|
      # rubocop:disable Lint/EmptyBlock -- the lock outlives the block; see the comment above
      OpenProject::Mutex.with_advisory_lock_transaction(entry) {}
      # rubocop:enable Lint/EmptyBlock
    end
  end

  # Unscoped by policy so completion, deletion and reassignment all resolve
  # to the same advisory identity.
  def raw_destination(target)
    case target
    in Backlogs::Target::SprintId
      Sprint.find_by(id: target.list_id)
    in Backlogs::Target::BucketId
      BacklogBucket.find_by(id: target.list_id)
    in Backlogs::Target::InboxId
      nil
    end
  end

  # lock! reloads under FOR UPDATE, so a concurrent completion, deletion or
  # reassignment commits before the availability query runs. Inbox has no
  # destination row; its placement is serialized by the advisory lock alone.
  def lock_destination_row!(destination)
    destination&.lock!
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # The anchor is scoped to the batch project because the acts_as_list scope
  # includes project_id: in a shared sprint another project's work package
  # would pass a container-only comparison, yet be unresolvable for
  # move_after, which then silently inserts at the top.
  def resolve_placement(target, prev_id)
    return Placement.new(mode: :append, anchor: last_non_batch_member(target)) if prev_id.nil?
    return Placement.new(mode: :top, anchor: nil) if prev_id.to_s.blank?

    anchor = WorkPackage.visible(user).where(project_id: batch_project_id).find_by(id: prev_id)
    anchor ? Placement.new(mode: :explicit, anchor:) : stale_predecessor_failure
  end

  # A member could have been moved to another project, or out of its source
  # container by a lifecycle service, or deleted, between the controller
  # loading the batch and the locks being taken. A hopped member would move
  # in a different acts_as_list scope, splitting the block, and the chained
  # prev_id would then cross scopes into move_after's silent insert-at-top.
  def cohort_intact?
    current = WorkPackage
      .visible(user)
      .where(id: work_packages.map(&:id), project_id: batch_project_id)
      .select(:id, :sprint_id, :backlog_bucket_id)

    current.size == work_packages.size && current.all? do |work_package|
      Backlogs::Target.for_work_package(work_package) == batch_source_targets.fetch(work_package.id)
    end
  end

  # Under lock the anchor must still be what placement resolution saw: same
  # project, same list, and for append still the last non-batch member. A
  # concurrently moved anchor would otherwise fall through to move_after's
  # silent insert-at-top.
  def revalidate_anchor(placement, target) # rubocop:disable Metrics/AbcSize
    anchor = placement.anchor
    return if anchor.nil?

    anchor.reload
    unless anchor.project_id == batch_project_id && Backlogs::Target.for_work_package(anchor) == target
      return stale_predecessor_failure
    end

    stale_predecessor_failure if placement.mode == :append && last_non_batch_member(target)&.id != anchor.id
  rescue ActiveRecord::RecordNotFound
    stale_predecessor_failure
  end

  # The contract only revalidates a sprint or bucket target when the
  # corresponding column changes, so a same-list reorder never triggers it
  # and a sprint completed after the page loaded stays an accepted
  # destination. Judged on freshly loaded rows rather than the batch's
  # loaded instances: a member's status, and so its mobility, may have
  # changed since the controller loaded it, which is exactly what this check
  # under the lock exists to catch.
  def revalidate_destination(target)
    return unavailable_target_failure unless target_available?(target)

    refused = destination_availability.refusing(target)
    refused_members_failure(refused) if refused.any?
  end

  def target_available?(target)
    destination_availability.candidate?(target)
  end

  # Freshly loaded rows, not the batch's loaded instances: a member's status,
  # and so its mobility, may have changed since the controller loaded it,
  # which is exactly what this check under the lock exists to catch.
  def destination_availability
    @destination_availability ||= Backlogs::WorkPackages::DestinationAvailability.new(
      project: batch_project,
      user:,
      work_packages: WorkPackage.where(id: work_packages.map(&:id)).to_a
    )
  end

  # Unscoped by policy so completion, deletion and reassignment all resolve
  # to the same advisory identity. DestinationAvailability stays the
  # authority once the locks have refreshed state.
  def raw_destination(target)
    case target
    in Backlogs::Target::SprintId
      Sprint.find_by(id: target.list_id)
    in Backlogs::Target::BucketId
      BacklogBucket.find_by(id: target.list_id)
    in Backlogs::Target::InboxId
      nil
    end
  end

  # lock! reloads under FOR UPDATE, so a concurrent completion, deletion or
  # reassignment commits before the candidate query above runs. Inbox has no
  # destination row; its append is serialized by the advisory lock alone.
  def lock_destination_row!(destination)
    destination&.lock!
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def last_non_batch_member(target)
    WorkPackage
      .visible(user)
      .where(project_id: batch_project_id, **target.attributes)
      .where.not(id: work_packages.map(&:id))
      .where.not(position: nil)
      .order(:position)
      .last
  end

  def batch_project_id
    @batch_project_id
  end

  def batch_project
    @batch_project
  end

  def batch_source_targets
    @batch_source_targets
  end

  def empty_batch_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.move_collection.invalid_ids"))
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

  # Refused whole, before any member moves, but naming the members that
  # refused rather than leaving the caller to guess.
  def refused_members_failure(members)
    failure = unavailable_target_failure
    members.each do |member|
      failure.add_dependent!(
        ServiceResult.failure(
          result: member,
          message: I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
        )
      )
    end
    failure
  end

  def mixed_projects_failure
    ServiceResult.failure(message: I18n.t("backlogs.work_packages.batch_update_service.mixed_projects"))
  end
end
