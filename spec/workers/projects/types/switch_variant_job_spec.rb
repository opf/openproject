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

RSpec.describe Projects::Types::SwitchVariantJob, with_flag: { type_variants: true } do
  shared_let(:user) { create(:admin) }
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }

  let(:project) { create(:project, types: [epic]) }
  let!(:work_package) { create(:work_package, project:, type: epic) }
  let(:source) { epic }
  let(:target) { design }
  # Instantiated rather than called through .perform_now so the spec can read
  # back the job_id the status row is keyed on.
  let(:job) { described_class.new(user:, project:, source:, target:) }

  def job_status = JobStatus::Status.find_by(job_id: job.job_id)

  describe "#perform" do
    subject(:perform_job) { job.perform_now }

    it "re-types the work packages and swaps the enabled types" do
      perform_job

      expect(work_package.reload.type).to eq(design)
      expect(project.reload.types).to contain_exactly(design)
    end

    it "records a success both surfaces can read" do
      perform_job

      expect(job_status).to be_success
      expect(job_status.message).to eq("The project now uses Epic: Design.")
    end

    context "when the target is outside the family" do
      let(:target) { create(:type, name: "Unrelated") }

      it "records the failure rather than raising" do
        perform_job

        expect(job_status).to be_failure
        expect(work_package.reload.type).to eq(epic)
      end
    end

    context "when a work package refuses the re-type" do
      before do
        errors = ActiveModel::Errors.new(work_package)
        errors.add(:base, "Type is not writable.")

        allow(WorkPackages::UpdateService)
          .to receive(:new).and_return(instance_double(WorkPackages::UpdateService,
                                                       call: ServiceResult.failure(errors:)))
      end

      # The service reports that through a dependent result, leaving its own
      # errors empty, so a naive message would be blank.
      it "reports the work package's own complaint" do
        perform_job

        expect(job_status).to be_failure
        expect(job_status.message).to include("Type is not writable.")
      end
    end
  end

  describe "the status row" do
    subject(:status) { JobStatus::Status.find_by(job_id: enqueued_job.job_id) }

    let(:enqueued_job) do
      User.execute_as(user) { described_class.perform_later(user:, project:, source:, target:) }
    end

    # Stamped at enqueue rather than at start, so a settings page opened while
    # the job is still queued can already name the switch.
    it "names the project, the source and the target as soon as it is queued" do
      expect(status.payload).to include("kind" => "type_switch",
                                        "project_id" => project.id,
                                        "source_id" => source.id,
                                        "target_id" => target.id)
    end

    # Guards the same constraint as the example below, but fails fast: putting
    # the project back here makes that one hang rather than fail.
    it "leaves the uniquely indexed reference empty" do
      expect(status.reference).to be_nil
    end

    # job_statuses has a unique index on (reference_type, reference_id), so
    # carrying the project there made the second switch of a project raise
    # RecordNotUnique — which upsert_status retries without bound.
    it "can be queued again for the same project" do
      status

      expect { User.execute_as(user) { described_class.perform_later(user:, project:, source: target, target: source) } }
        .to change(JobStatus::Status, :count).by(1)
    end
  end
end
