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

RSpec.describe ProjectIdentifiers::FinishSemanticConversionJob do
  subject(:job) { described_class.new }

  let(:batch) { instance_double(GoodJob::Batch, discarded?: false) }
  let(:update_service) { instance_double(Settings::UpdateService, call: ServiceResult.success) }

  before do
    allow(Settings::UpdateService).to receive(:new).with(user: User.system).and_return(update_service)
    allow(ProjectIdentifiers::RevertInstanceToClassicIdsJob).to receive(:perform_later)
  end

  describe "#perform" do
    context "when no projects remain from the start" do
      before { allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set.new) }

      it "enables semantic mode without running any conversion" do
        allow(ProjectIdentifiers::ConvertProjectToSemanticService).to receive(:new)
        job.perform(batch)
        expect(ProjectIdentifiers::ConvertProjectToSemanticService).not_to have_received(:new)
        expect(update_service).to have_received(:call)
          .with(work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC)
      end
    end

    context "when projects are cleared after the first sweep" do
      let(:project) { instance_double(Project) }
      let(:service) { instance_double(ProjectIdentifiers::ConvertProjectToSemanticService, call: nil) }

      before do
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set[1], Set.new)
        allow(Project).to receive(:find_by).with(id: 1).and_return(project)
        allow(ProjectIdentifiers::ConvertProjectToSemanticService).to receive(:new).with(project).and_return(service)
      end

      it "runs one conversion sweep then enables semantic mode" do
        job.perform(batch)
        expect(service).to have_received(:call).once
        expect(update_service).to have_received(:call)
          .with(work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC)
      end
    end

    context "when projects are cleared on the last sweep" do
      let(:project) { instance_double(Project) }
      let(:service) { instance_double(ProjectIdentifiers::ConvertProjectToSemanticService, call: nil) }

      before do
        pending_sets = Array.new(described_class::MAX_SWEEPS, Set[1]) + [Set.new]
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(*pending_sets)
        allow(Project).to receive(:find_by).with(id: 1).and_return(project)
        allow(ProjectIdentifiers::ConvertProjectToSemanticService).to receive(:new).with(project).and_return(service)
      end

      it "enables semantic mode after the final sweep clears all projects" do
        job.perform(batch)
        expect(service).to have_received(:call).exactly(described_class::MAX_SWEEPS).times
        expect(update_service).to have_received(:call)
          .with(work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC)
      end
    end

    context "when projects still remain after all sweeps" do
      let(:project) { instance_double(Project) }
      let(:service) { instance_double(ProjectIdentifiers::ConvertProjectToSemanticService, call: nil) }

      before do
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set[1])
        allow(Project).to receive(:find_by).with(id: 1).and_return(project)
        allow(ProjectIdentifiers::ConvertProjectToSemanticService).to receive(:new).with(project).and_return(service)
        allow(Rails.logger).to receive(:error)
      end

      it "does not enable semantic mode and reverts to classic" do
        job.perform(batch)
        expect(update_service).not_to have_received(:call)
        expect(ProjectIdentifiers::RevertInstanceToClassicIdsJob).to have_received(:perform_later)
      end

      it "logs the failure reason" do
        job.perform(batch)
        expect(Rails.logger).to have_received(:error)
          .with(/Giving up after #{described_class::MAX_SWEEPS} sweeps/o)
      end

      it "runs the maximum number of sweeps before giving up" do
        job.perform(batch)
        expect(service).to have_received(:call).exactly(described_class::MAX_SWEEPS).times
      end
    end

    context "when a remaining project no longer exists" do
      before do
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set[99], Set.new)
        allow(Project).to receive(:find_by).with(id: 99).and_return(nil)
        allow(ProjectIdentifiers::ConvertProjectToSemanticService).to receive(:new)
      end

      it "skips the missing project and still enables semantic mode" do
        job.perform(batch)
        expect(ProjectIdentifiers::ConvertProjectToSemanticService).not_to have_received(:new)
        expect(update_service).to have_received(:call)
          .with(work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC)
      end
    end

    context "when enabling semantic mode fails" do
      before do
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids).and_return(Set.new)
        allow(update_service).to receive(:call)
          .and_return(instance_double(ServiceResult, success?: false, message: "update failed"))
        allow(Rails.logger).to receive(:error)
      end

      it "reverts to classic" do
        job.perform(batch)
        expect(ProjectIdentifiers::RevertInstanceToClassicIdsJob).to have_received(:perform_later)
      end

      it "logs the failure reason" do
        job.perform(batch)
        expect(Rails.logger).to have_received(:error).with(/Failed to enable semantic mode/)
      end
    end

    context "when the batch had failures" do
      let(:batch) { instance_double(GoodJob::Batch, discarded?: true) }

      before { allow(Rails.logger).to receive(:error) }

      it "does not run a corrective sweep" do
        allow(ProjectIdentifiers::PendingProjectsFinder).to receive(:project_ids)
        job.perform(batch)
        expect(ProjectIdentifiers::PendingProjectsFinder).not_to have_received(:project_ids)
      end

      it "does not enable semantic mode" do
        job.perform(batch)
        expect(update_service).not_to have_received(:call)
      end

      it "enqueues RevertInstanceToClassicIdsJob" do
        job.perform(batch)
        expect(ProjectIdentifiers::RevertInstanceToClassicIdsJob).to have_received(:perform_later)
      end

      it "logs the failure reason" do
        job.perform(batch)
        expect(Rails.logger).to have_received(:error).with(/Batch had failures/)
      end
    end
  end
end
