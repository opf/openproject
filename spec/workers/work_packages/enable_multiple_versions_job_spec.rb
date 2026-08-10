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

require "rails_helper"

RSpec.describe WorkPackages::EnableMultipleVersionsJob do
  subject(:job) { described_class.new }

  shared_let(:project) { create(:project) }

  before do
    Setting.work_package_multiple_versions = false
  end

  describe "#perform" do
    it "flips the setting from false to true" do
      expect { job.perform }.to change(Setting, :work_package_multiple_versions?).from(false).to(true)
    end

    it "inserts a missing target join row for a work package whose version_id bypassed the callbacks" do
      version = create(:version, project:)
      work_package = create(:work_package, project:, version: nil)
      work_package.update_column(:version_id, version.id)

      expect { job.perform }
        .to change { WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").count }.from(0).to(1)
      expect(WorkPackageVersion.find_by(work_package_id: work_package.id, kind: "target").version_id).to eq(version.id)
    end

    it "does not duplicate an existing target row" do
      version = create(:version, project:)
      work_package = create(:work_package, project:, version:)

      expect { job.perform }
        .not_to change { WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").count }.from(1)
    end

    it "does not touch observed_in rows" do
      target_version = create(:version, project:)
      observed_version = create(:version, project:)
      work_package = create(:work_package, project:, version: target_version)
      create(:work_package_version, work_package:, version: observed_version, kind: "observed_in")

      expect { job.perform }
        .not_to change { WorkPackageVersion.where(work_package_id: work_package.id, kind: "observed_in").count }.from(1)
    end

    it "leaves a work package with a nil version_id alone" do
      work_package = create(:work_package, project:, version: nil)

      expect { job.perform }
        .not_to change { WorkPackageVersion.where(work_package_id: work_package.id).count }.from(0)
    end

    it "does nothing on a second run once the setting is already enabled" do
      version = create(:version, project:)
      work_package = create(:work_package, project:, version: nil)
      work_package.update_column(:version_id, version.id)

      job.perform

      expect { described_class.new.perform }
        .not_to change { WorkPackageVersion.where(work_package_id: work_package.id, kind: "target").count }.from(1)
      expect(Setting.work_package_multiple_versions?).to be true
    end

    it "raises so GoodJob records the failure when the setting is not writable" do
      allow(Settings::Definition[:work_package_multiple_versions]).to receive(:writable?).and_return(false)

      expect { job.perform }.to raise_error(described_class::EnablingFailed, /not writable/i)
      expect(Setting.work_package_multiple_versions?).to be false
    end
  end

  describe ".in_progress?" do
    it "is false when no job has been enqueued" do
      expect(described_class.in_progress?).to be false
    end

    context "when a job is enqueued but not yet finished",
            with_good_job_batches: [described_class] do
      it "is true" do
        described_class.perform_later
        expect(described_class.in_progress?).to be true
      end
    end

    context "when the enqueued job has finished",
            with_good_job_batches: [described_class] do
      it "is false" do
        described_class.perform_later
        GoodJob::Job.where(job_class: described_class.name).update_all(finished_at: Time.current)
        expect(described_class.in_progress?).to be false
      end
    end
  end
end
