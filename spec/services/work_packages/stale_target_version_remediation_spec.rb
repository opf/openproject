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

RSpec.describe WorkPackages::StaleTargetVersionRemediation, type: :model do
  subject(:remediation) { described_class.new }

  shared_let(:project) { create(:project) }

  def repair_cause
    Journal::CausedBySystemUpdate.new(feature: "target_versions_repaired")
  end

  # Mirrors the writes the deleted WorkPackages::EnableMultipleVersionsJob made: a direct
  # target row insert followed by a system journal carrying the same cause.
  def stale_repair!(work_package, stale_version, user: User.system)
    WorkPackageVersion.create!(work_package:, version: stale_version, kind: "target")

    Journal::NotificationConfiguration.with(false) do
      Journals::CreateService.new(work_package, user).call(cause: repair_cause)
    end
  end

  # Builds the flavor-1 corruption: version A was replaced by version B through the normal
  # update path, then the frozen version_id column (still holding A) got reinserted as a
  # second target row.
  def build_reinstated_corruption
    version_a = create(:version, project:)
    version_b = create(:version, project:)

    work_package = create(:work_package, project:)
    travel(6.minutes)

    work_package.add_journal(user: create(:user))
    work_package.target_version_ids_replacements = [version_a.id]
    work_package.save!
    travel(6.minutes)

    work_package.add_journal(user: create(:user))
    work_package.target_version_ids_replacements = [version_b.id]
    work_package.save!

    work_package.update_column(:version_id, version_a.id)
    travel(6.minutes)

    stale_repair!(work_package, version_a)

    [work_package, version_a, version_b]
  end

  describe "#findings" do
    it "covers only the given work packages when scoped, and everything otherwise" do
      other_work_package = create(:work_package, project:)
      other_version = create(:version, project:)
      other_work_package.update_column(:version_id, other_version.id)
      stale_repair!(other_work_package, other_version)

      scoped_work_package, = build_reinstated_corruption

      expect(remediation.findings.map(&:work_package))
        .to contain_exactly(scoped_work_package, other_work_package)

      scoped = described_class.new(work_package_ids: [scoped_work_package.id])
      expect(scoped.findings.map(&:work_package)).to contain_exactly(scoped_work_package)
    end

    it "covers only repair journals created within the given time range" do
      work_package, = build_reinstated_corruption
      repair_time = work_package.journals.reload.last.created_at

      covering = described_class.new(created_between: (repair_time - 1.minute)..(repair_time + 1.minute))
      expect(covering.findings.map(&:work_package)).to contain_exactly(work_package)

      outside = described_class.new(created_between: (repair_time + 1.hour)..(repair_time + 2.hours))
      expect(outside.findings).to be_empty
    end

    it "announces an upper-bound-only time scope as created before that time" do
      out = StringIO.new
      described_class.new(created_between: ..Time.zone.now).report(out:)

      expect(out.string).to include("repair journals created before")
    end

    it "flags a version that was reinstated after being replaced" do
      work_package, version_a, version_b = build_reinstated_corruption

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:remove)
      expect(finding.stale_version).to eq(version_a)
      expect(work_package.target_versions.reload).to contain_exactly(version_a, version_b)
    end

    it "flags a version that was reinstated after being removed entirely" do
      version_a = create(:version, project:, name: "A")

      work_package = create(:work_package, project:)
      travel(6.minutes)

      work_package.add_journal(user: create(:user))
      work_package.target_version_ids_replacements = [version_a.id]
      work_package.save!
      travel(6.minutes)

      work_package.add_journal(user: create(:user))
      work_package.target_version_ids_replacements = []
      work_package.save!

      work_package.update_column(:version_id, version_a.id)
      travel(6.minutes)

      stale_repair!(work_package, version_a)

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:remove)
      expect(finding.stale_version).to eq(version_a)
    end

    it "skips a work package whose target versions were corrected again after the repair" do
      work_package, version_a, version_b = build_reinstated_corruption

      travel(6.minutes)
      work_package.add_journal(user: create(:user))
      work_package.target_version_ids_replacements = [version_b.id]
      work_package.save!

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:skip_manual_change)
      expect(finding.stale_version).to eq(version_a)
    end

    it "still flags the stale version when a later journal leaves target versions untouched" do
      work_package, version_a, = build_reinstated_corruption

      travel(6.minutes)
      work_package.add_journal(user: create(:user))
      work_package.subject = "Renamed after the repair"
      work_package.save!

      finding = remediation.findings.sole

      expect(finding.action).to eq(:remove)
      expect(finding.stale_version).to eq(version_a)
    end

    it "leaves alone a work package that never had a target version before the repair" do
      version_a = create(:version, project:, name: "A")

      work_package = create(:work_package, project:)
      work_package.update_column(:version_id, version_a.id)
      travel(6.minutes)

      stale_repair!(work_package, version_a)

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:skip_no_prior_version)
      expect(finding.stale_version).to eq(version_a)
    end

    it "flags an anomaly when the added version does not match the frozen column value" do
      version_a = create(:version, project:, name: "A")
      version_b = create(:version, project:, name: "B")
      version_c = create(:version, project:, name: "C")

      work_package = create(:work_package, project:)
      travel(6.minutes)

      work_package.add_journal(user: create(:user))
      work_package.target_version_ids_replacements = [version_b.id]
      work_package.save!

      work_package.update_column(:version_id, version_a.id)
      travel(6.minutes)

      stale_repair!(work_package, version_c)

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:skip_anomaly)
      expect(finding.stale_version).to be_nil
    end

    it "flags an anomaly instead of crashing when the stale version was later deleted" do
      work_package, version_a, = build_reinstated_corruption

      version_a.destroy!

      finding = remediation.findings.sole

      expect(finding.work_package).to eq(work_package)
      expect(finding.action).to eq(:skip_anomaly)
      expect(finding.stale_version).to be_nil
    end

    it "skips a journal whose work package was deleted, without crashing" do
      work_package, = build_reinstated_corruption

      WorkPackage.where(id: work_package.id).delete_all

      expect(remediation.findings).to be_empty
    end
  end

  describe "#report" do
    it "prints one line per finding and a summary, without changing any data" do
      work_package, version_a, version_b = build_reinstated_corruption

      out = StringIO.new
      expect { remediation.report(out:) }.not_to change {
        WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id).sort
      }.from([version_a.id, version_b.id].sort)
      expect { remediation.report(out:) }.not_to change(Journal, :count)

      output = out.string
      expect(output).to include("##{work_package.id}")
      expect(output).to include(version_a.name)
      expect(output).to include("remove")
      expect(output).to include("would fix 1 work packages: #{work_package.id}")
      expect(output).to include("skipped 0 (manual change since)")
      expect(output).to include("skipped 0 (no prior version)")
      expect(output).to include("skipped 0 (anomaly - needs human review)")
      expect(output).to include("already corrected 0")
    end

    it "lists anomalies with the work package and the concrete mismatch, for human review" do
      version_a = create(:version, project:, name: "A")
      version_b = create(:version, project:, name: "B")
      version_c = create(:version, project:, name: "C")

      work_package = create(:work_package, project:)
      travel(6.minutes)

      work_package.add_journal(user: create(:user))
      work_package.target_version_ids_replacements = [version_b.id]
      work_package.save!

      work_package.update_column(:version_id, version_a.id)
      travel(6.minutes)

      stale_repair!(work_package, version_c)

      out = StringIO.new
      remediation.report(out:)
      output = out.string

      expect(output).to include("skipped 1 (anomaly - needs human review)")
      expect(output).to include("Anomalies needing manual review:")
      expect(output).to include("WP##{work_package.id}")
      expect(output).to include("[#{version_c.id}]")
      expect(output).to include(version_a.id.to_s)
    end
  end

  describe "#apply" do
    it "removes exactly the stale target row and journals the correction, under a dedicated " \
       "cause, without notifying" do
      work_package, version_a, version_b = build_reinstated_corruption
      create(:work_package_version, work_package:, version: version_a, kind: "observed_in")

      repair_journal = work_package.journals.reload.last
      notifications_before = Notification.count

      out = StringIO.new
      results = remediation.apply(out:)

      expect(Notification.count).to eq(notifications_before)
      expect(results.sole.action).to eq(:remove)
      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(version_b.id)
      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "observed_in").pluck(:version_id))
        .to contain_exactly(version_a.id)

      corrective_journal = work_package.journals.reload.order(:version).last
      expect(corrective_journal.id).not_to eq(repair_journal.id)
      expect(corrective_journal.version).to eq(repair_journal.version + 1)
      expect(corrective_journal.cause_type).to eq("system_update")
      expect(corrective_journal.cause["feature"]).to eq("stale_target_versions_removed")
      expect(corrective_journal.target_version_journals.pluck(:version_id)).to contain_exactly(version_b.id)

      output = out.string
      expect(output).to include("fixed 1 work packages: #{work_package.id}")
    end

    it "creates a journal separate from the repair journal even when applied immediately after " \
       "it, because the differing cause blocks aggregation" do
      work_package, = build_reinstated_corruption
      repair_journal = work_package.journals.reload.last

      expect { remediation.apply }.to change { work_package.journals.reload.count }.by(1)

      expect(work_package.journals.exists?(id: repair_journal.id)).to be true
      corrective_journal = work_package.journals.order(:version).last
      expect(corrective_journal.id).not_to eq(repair_journal.id)
      expect(corrective_journal.user).to eq(repair_journal.user)
      expect(corrective_journal.cause["feature"]).to eq("stale_target_versions_removed")
    end

    it "is idempotent: a second pass sees the correction and does nothing" do
      work_package, _version_a, version_b = build_reinstated_corruption
      remediation.apply

      second_pass = described_class.new.findings

      expect(second_pass.sole.action).to eq(:already_corrected)
      expect(second_pass.sole.work_package).to eq(work_package)

      expect { described_class.new.apply }.not_to change { work_package.journals.count }
      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(version_b.id)
    end

    it "rolls back the removal and reports a failure when the corrective journal is not written" do
      work_package, version_a, version_b = build_reinstated_corruption

      silent_service = instance_double(Journals::CreateService,
                                       call: ServiceResult.success(result: nil))
      allow(Journals::CreateService).to receive(:new).and_return(silent_service)

      out = StringIO.new
      results = remediation.apply(out:)

      expect(results.sole.action).to eq(:failed)
      expect(WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(version_a.id, version_b.id)

      output = out.string
      expect(output).to include("failed 1 (rolled back): #{work_package.id}")
      expect(output).to include("WP##{work_package.id}: corrective journal was not created")
    end

    it "continues with the remaining work packages when one of them fails" do
      failing_work_package, failing_version_a, failing_version_b = build_reinstated_corruption

      # Journals are stamped with database now(), which time travel cannot reach, so a
      # work package created while the clock is traveled ahead would order its journals
      # backwards. Return to real time before building the second corruption.
      travel_back
      healthy_work_package, _healthy_version_a, healthy_version_b = build_reinstated_corruption

      allow(Journals::CreateService).to receive(:new).and_call_original
      silent_service = instance_double(Journals::CreateService,
                                       call: ServiceResult.success(result: nil))
      allow(Journals::CreateService).to receive(:new)
        .with(failing_work_package, User.system).and_return(silent_service)

      out = StringIO.new
      results = remediation.apply(out:)

      expect(results.map { [it.work_package, it.action] })
        .to contain_exactly([failing_work_package, :failed], [healthy_work_package, :remove])

      expect(WorkPackageVersion.where(work_package_id: failing_work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(failing_version_a.id, failing_version_b.id)
      expect(WorkPackageVersion.where(work_package_id: healthy_work_package.id, kind: "target").pluck(:version_id))
        .to contain_exactly(healthy_version_b.id)

      output = out.string
      expect(output).to include("fixed 1 work packages: #{healthy_work_package.id}")
      expect(output).to include("failed 1 (rolled back): #{failing_work_package.id}")
    end
  end
end
