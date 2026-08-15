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

require "spec_helper"

RSpec.describe Backlogs::WorkPackages::BatchUpdateService, type: :model do
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages view_sprints manage_sprint_items]
           })
  end
  let!(:sprint) { create(:sprint, project:) }
  let!(:bucket) { create(:backlog_bucket, project:) }

  let!(:sprint_wp1) { create(:work_package, sprint:, position: 1, type:, project:) }
  let!(:sprint_wp2) { create(:work_package, sprint:, position: 2, type:, project:) }
  let!(:sprint_wp3) { create(:work_package, sprint:, position: 3, type:, project:) }
  let!(:bucket_wp1) { create(:work_package, backlog_bucket: bucket, position: 1, type:, project:) }
  let!(:bucket_wp2) { create(:work_package, backlog_bucket: bucket, position: 2, type:, project:) }

  def service(work_packages)
    described_class.new(user:, work_packages:)
  end

  def sprint_order
    sprint.work_packages_for(project).pluck(:id)
  end

  it "moves a cross-list batch as one contiguous block after the predecessor" do
    result = service([bucket_wp1, sprint_wp3])
      .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp1.id.to_s)

    expect(result).to be_success
    expect(result.result.map(&:id)).to eq [bucket_wp1.id, sprint_wp3.id]
    expect(sprint_order).to eq [sprint_wp1.id, bucket_wp1.id, sprint_wp3.id, sprint_wp2.id]
    expect(sprint.work_packages_for(project).pluck(:position)).to eq [1, 2, 3, 4]
    expect(bucket_wp1.reload.backlog_bucket_id).to be_nil
  end

  it "inserts at the top for a blank prev_id" do
    result = service([sprint_wp2, sprint_wp3])
      .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "")

    expect(result).to be_success
    expect(sprint_order).to eq [sprint_wp2.id, sprint_wp3.id, sprint_wp1.id]
    expect(sprint.work_packages_for(project).pluck(:position)).to eq [1, 2, 3]
  end

  it "treats a whitespace-only prev_id as top, like a blank one" do
    result = service([sprint_wp3])
      .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "  ")

    expect(result).to be_success
    expect(sprint_order).to eq [sprint_wp3.id, sprint_wp1.id, sprint_wp2.id]
  end

  it "appends after the last non-batch member for an absent prev_id" do
    result = service([sprint_wp1, bucket_wp2])
      .call(list_type: "sprint", list_id: sprint.id.to_s)

    expect(result).to be_success
    # sprint_wp1 was already in the sprint: append gathers it behind the last
    # member that is NOT part of the batch (sprint_wp3), not behind itself.
    expect(sprint_order).to eq [sprint_wp2.id, sprint_wp3.id, sprint_wp1.id, bucket_wp2.id]
    expect(sprint.work_packages_for(project).pluck(:position)).to eq [1, 2, 3, 4]
  end

  it "appends at the top of an otherwise empty target" do
    empty_bucket = create(:backlog_bucket, project:)

    result = service([sprint_wp1, sprint_wp2])
      .call(list_type: "backlog_bucket", list_id: empty_bucket.id.to_s)

    expect(result).to be_success
    expect(WorkPackage.where(backlog_bucket: empty_bucket).order(:position).pluck(:id))
      .to eq [sprint_wp1.id, sprint_wp2.id]
    expect(WorkPackage.where(backlog_bucket: empty_bucket).order(:position).pluck(:position))
      .to eq [1, 2]
    # The source sprint loses two of its three members: a gap left behind
    # instead of renumbering the remaining member down to position 1 would
    # corrupt future inserts there without ever failing an id-only check.
    expect(sprint_order).to eq [sprint_wp3.id]
    expect(sprint.work_packages_for(project).pluck(:position)).to eq [1]
  end

  it "fails for an invalid target" do
    result = service([sprint_wp1]).call(list_type: "unknown", list_id: "1")

    expect(result).to be_failure
    expect(result.message).to eq I18n.t("backlogs.work_packages.update_service.invalid_target_type")
  end

  describe "atomicity" do
    it "rolls back every member when a later member fails", with_ee: %i[readonly_work_packages] do
      # A readonly status blocks every attribute write through
      # WorkPackage#modification_blocked, so the inner service fails for it.
      readonly_status = create(:status, is_readonly: true)
      blocked = create(:work_package, backlog_bucket: bucket, position: 3, type:, project:,
                                      status: readonly_status)

      result = service([bucket_wp1, blocked])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp1.id.to_s)

      expect(result).to be_failure
      expect(bucket_wp1.reload.backlog_bucket_id).to eq bucket.id
      expect(bucket_wp1.position).to eq 1
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "returns a failed result and rolls back when a later member raises" do
      # An operational exception from a later member must not escape as a
      # 500: the design requires one failed batch result after rollback.
      # The raw adapter message ("boom") is internal detail and unlocalized,
      # so the user-facing result carries a generic i18n message while the
      # exception itself is logged.
      failing_inner = Backlogs::WorkPackages::UpdateService.new(user:, work_package: bucket_wp2)
      allow(failing_inner).to receive(:call).and_raise(ActiveRecord::StatementInvalid, "boom")
      allow(Backlogs::WorkPackages::UpdateService).to receive(:new).and_call_original
      allow(Backlogs::WorkPackages::UpdateService)
        .to receive(:new).with(user:, work_package: bucket_wp2)
        .and_return(failing_inner)
      logged_message = nil
      allow(Rails.logger).to receive(:error) { |&blk| logged_message = blk.call }

      result = service([bucket_wp1, bucket_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "")

      expect(result).to be_failure
      expect(result.message)
        .to eq I18n.t("backlogs.work_packages.batch_update_service.unexpected_failure")
      expect(logged_message).to include("boom")
      expect(bucket_wp1.reload).to have_attributes(backlog_bucket_id: bucket.id, position: 1)
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    # The established call_hook observation pattern — see
    # update_service_persistence_spec.rb's "after-commit hooks" describe.
    it "fires update hooks only after the whole batch commits, each observing the final order" do
      observed_orders = []
      observed_states = []
      allow(OpenProject::Hook).to receive(:call_hook).and_call_original
      allow(OpenProject::Hook).to receive(:call_hook).with(:work_package_after_update, anything) do |_hook, context|
        observed_orders << sprint.work_packages_for(project).pluck(:id)
        # The hook context carries the WorkPackage INSTANCE
        # (WorkPackage#call_after_update_hook builds it from `self`), not a
        # fresh DB read: read straight off the instance's own attributes, no
        # reload/query here, to prove it already holds its final state.
        hook_wp = context[:work_package]
        observed_states << [hook_wp.id, hook_wp.sprint_id, hook_wp.backlog_bucket_id, hook_wp.position]
      end

      # A same-list downward reorder: sprint_wp1 is processed first and lands
      # above sprint_wp2's own original slot, so sprint_wp2's later
      # remove_from_list (removing IT from that slot) decrements
      # sprint_wp1's already-written row out from under its in-memory
      # instance — exactly the shape that exposes a stale hook context.
      service([sprint_wp1, sprint_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp3.id.to_s)

      final_order = [sprint_wp3.id, sprint_wp1.id, sprint_wp2.id]
      expect(observed_orders.size).to eq 2
      # Every hook call already sees the complete committed batch — no hook
      # may observe a partially moved intermediate state.
      expect(observed_orders).to all(eq(final_order))
      expect(observed_states).to contain_exactly(
        [sprint_wp1.id, sprint.id, nil, 2],
        [sprint_wp2.id, sprint.id, nil, 3]
      )
    end

    it "fires no update hook for a rolled-back batch", with_ee: %i[readonly_work_packages] do
      readonly_status = create(:status, is_readonly: true)
      blocked = create(:work_package, backlog_bucket: bucket, position: 3, type:, project:,
                                      status: readonly_status)
      allow(OpenProject::Hook).to receive(:call_hook).and_call_original

      service([bucket_wp1, blocked])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "")

      expect(OpenProject::Hook)
        .not_to have_received(:call_hook).with(:work_package_after_update, anything)
    end
  end

  describe "batch project cohort" do
    it "rejects a batch whose project changed after loading but before the lock" do
      other_project = create(:project, types: [type])
      hopped = sprint_wp2

      batch = service([sprint_wp1, hopped])
      # Simulate the race directly on the row, bypassing the loaded instance:
      # a member hops to another project between controller load and lock
      # acquisition.
      WorkPackage.find(hopped.id).update_columns(project_id: other_project.id)

      result = batch.call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "")

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_batch")
      # Nothing moved: the sprint order is exactly what it was before the
      # call, and the hopped member is left exactly where the race put it —
      # the rejection does not depend on the inner service failing.
      expect(sprint.work_packages.order(:position).pluck(:id)).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
      expect(sprint.work_packages.order(:position).pluck(:position)).to eq [1, 2, 3]
      expect(hopped.reload.project_id).to eq other_project.id
      expect(sprint_wp1.reload.project_id).to eq project.id
    end

    it "rejects a batch with a member deleted after loading" do
      batch = service([sprint_wp1, sprint_wp2])
      # Simulate the race directly on the row, bypassing the loaded instance:
      # a member is deleted between controller load and lock acquisition.
      WorkPackage.where(id: sprint_wp2.id).delete_all

      result = batch.call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "")

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_batch")
      expect(sprint_wp1.reload.position).to eq 1
    end
  end

  describe "advisory locks" do
    it "acquires the batch and predecessor locks in ascending id order" do
      locked = []
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
        .and_wrap_original do |method, entry, *args, &block|
          locked << entry.id
          method.call(entry, *args, &block)
        end

      # Deliberately out-of-order input, predecessor id between them.
      service([sprint_wp3, sprint_wp1])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp2.id.to_s)

      batch_and_predecessor = [sprint_wp3.id, sprint_wp1.id, sprint_wp2.id].sort
      expect(locked.first(3)).to eq batch_and_predecessor
    end

    it "locks the implicit append anchor for an absent prev_id" do
      locked = []
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction)
        .and_wrap_original do |method, entry, *args, &block|
          locked << entry.id
          method.call(entry, *args, &block)
        end

      # Appending bucket_wp1 to the sprint: the real anchor is sprint_wp3
      # (last non-batch member) — it must be locked and revalidated, or a
      # concurrent move of it would let move_after silently insert at top.
      service([bucket_wp1])
        .call(list_type: "sprint", list_id: sprint.id.to_s)

      expect(locked.first(2)).to eq [bucket_wp1.id, sprint_wp3.id].sort
    end
  end

  describe "target availability" do
    it "rejects a same-list reorder inside a sprint that completed after load" do
      sprint.update!(status: "completed")

      result = service([sprint_wp1])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp3.id.to_s)

      expect(result).to be_failure
      expect(result.message)
        .to eq I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
      expect(sprint.work_packages_for(project).pluck(:position)).to eq [1, 2, 3]
    end

    it "rejects a cross-list move into a sprint that completed after load" do
      sprint.update!(status: "completed")

      result = service([bucket_wp1])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp1.id.to_s)

      expect(result).to be_failure
      expect(result.message)
        .to eq I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
      expect(bucket_wp1.reload.backlog_bucket_id).to eq bucket.id
      expect(bucket_wp1.position).to eq 1
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "rejects a backlog bucket target from another project" do
      other_project = create(:project, types: [type])
      foreign_bucket = create(:backlog_bucket, project: other_project)

      result = service([sprint_wp1])
        .call(list_type: "backlog_bucket", list_id: foreign_bucket.id.to_s)

      expect(result).to be_failure
      expect(result.message)
        .to eq I18n.t("backlogs.work_packages.batch_update_service.unavailable_target")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end
  end

  describe "stale predecessor" do
    it "rejects a predecessor that is not in the target list" do
      result = service([sprint_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: bucket_wp1.id.to_s)

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "rejects a predecessor contained in the batch" do
      result = service([sprint_wp1, sprint_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: sprint_wp1.id.to_s)

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "rejects a missing predecessor" do
      result = service([sprint_wp1])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "999999")

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "rejects a shared-sprint predecessor from another project" do
      # A shared sprint can contain another project's work packages, but the
      # acts_as_list scope includes project_id: such an anchor would be
      # unresolvable for move_after and silently fall back to the top.
      other_project = create(:project, types: [type])
      foreign_wp = create(:work_package, sprint:, type:, project: other_project)

      result = service([sprint_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: foreign_wp.id.to_s)

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "rejects a malformed prev_id instead of integer-casting it" do
      result = service([sprint_wp2])
        .call(list_type: "sprint", list_id: sprint.id.to_s, prev_id: "#{sprint_wp1.id}abc")

      expect(result).to be_failure
      expect(result.message).to eq I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor")
      expect(sprint_order).to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end
  end
end
