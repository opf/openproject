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

RSpec.describe Projects::ScheduleDeletionService, type: :model do
  let(:contract_class) do
    contract = double("contract_class", "<=": true)

    allow(contract)
      .to receive(:new)
      .with(project, user, options: {})
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double("contract_instance", validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double("contract_errors")
  end
  let(:project_valid) { true }
  let(:project) { build_stubbed(:project) }
  let(:instance) do
    described_class.new(user:,
                        model: project,
                        contract_class:)
  end
  let(:archive_success) do
    true
  end
  let(:archive_errors) do
    double("archive_errors")
  end
  let(:archive_result) do
    ServiceResult.new result: project,
                      success: archive_success,
                      errors: archive_errors
  end
  let!(:archive_service) do
    service = double("archive_service_instance")

    allow(Projects::ArchiveService)
      .to receive(:new)
      .with(user:,
            model: project)
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(archive_result)

    service
  end
  let(:user) { build_stubbed(:admin) }

  subject { instance.call }

  before do
    allow(Projects::DeleteProjectJob)
      .to receive(:perform_later)
  end

  context "if contract and archiving are successful" do
    it "archives the project and creates a delayed job" do
      expect(subject).to be_success

      expect(archive_service)
        .to have_received(:call)

      expect(Projects::DeleteProjectJob)
        .to have_received(:perform_later)
        .with(user:, project:)
    end
  end

  context "if project is archived already" do
    let(:project) { build_stubbed(:project, active: false) }

    it "does not call archive service" do
      expect(subject).to be_success

      expect(archive_service)
        .not_to have_received(:call)

      expect(Projects::DeleteProjectJob)
        .to have_received(:perform_later)
        .with(user:, project:)
    end
  end

  context "if contract fails" do
    let(:contract_valid) { false }

    it "is failure" do
      expect(subject).to be_failure
    end

    it "returns the contract errors" do
      expect(subject.errors)
        .to eql contract_errors
    end

    it "does not schedule a job" do
      expect(Projects::DeleteProjectJob)
        .not_to receive(:new)

      subject
    end
  end

  context "if archiving fails" do
    let(:archive_success) { false }

    it "is failure" do
      expect(subject).to be_failure
    end

    it "returns the contract errors" do
      expect(subject.errors)
        .to eql archive_errors
    end

    it "does not schedule a job" do
      expect(Projects::DeleteProjectJob)
        .not_to receive(:new)

      subject
    end
  end
end
