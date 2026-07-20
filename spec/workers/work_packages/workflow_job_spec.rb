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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::WorkflowJob do
  let(:work_package) { build_stubbed(:work_package) }
  let(:changes) { { "status_id" => [1, 2] } }
  let(:journal_user) { build_stubbed(:user) }
  let(:journal) { instance_double(Journal, journable: work_package, initial?: initial, user: journal_user) }
  let(:initial) { false }

  let(:reupload_service) do
    instance_double(Projects::CreationWizard::ReuploadArtifactOnStatusChangesService, call!: nil)
  end
  let(:type_export_service) do
    instance_double(WorkPackages::TypeArtefactExport::ExportOnStatusChangeService, call!: nil)
  end

  let(:reupload_applicable) { true }
  let(:type_export_applicable) { true }

  before do
    allow(Projects::CreationWizard::ReuploadArtifactOnStatusChangesService)
      .to receive_messages(new: reupload_service, applicable?: reupload_applicable)
    allow(WorkPackages::TypeArtefactExport::ExportOnStatusChangeService)
      .to receive_messages(new: type_export_service, applicable?: type_export_applicable)
  end

  subject(:perform) { described_class.new.perform(journal, changes) }

  context "when the journal is not the initial one" do
    it "invokes both the creation-wizard reupload and the type artefact export" do
      perform

      expect(reupload_service).to have_received(:call!).with(changes:)
      expect(type_export_service).to have_received(:call!).with(changes:)
    end

    it "acts as the journal's user so generated artefacts are attributed to them" do
      current_user_during_call = nil
      allow(type_export_service).to receive(:call!) { current_user_during_call = User.current }

      perform

      expect(current_user_during_call).to eq(journal_user)
    end

    context "when only one service is applicable" do
      let(:reupload_applicable) { false }

      it "only instantiates and invokes the applicable service" do
        perform

        expect(Projects::CreationWizard::ReuploadArtifactOnStatusChangesService).not_to have_received(:new)
        expect(type_export_service).to have_received(:call!).with(changes:)
      end
    end

    context "when no service is applicable" do
      let(:reupload_applicable) { false }
      let(:type_export_applicable) { false }

      it "does not set up a user context or instantiate any service" do
        allow(User).to receive(:execute_as)

        perform

        expect(User).not_to have_received(:execute_as)
        expect(Projects::CreationWizard::ReuploadArtifactOnStatusChangesService).not_to have_received(:new)
        expect(WorkPackages::TypeArtefactExport::ExportOnStatusChangeService).not_to have_received(:new)
      end
    end
  end

  context "when the journal is the initial one" do
    let(:initial) { true }

    it "does not invoke either handler" do
      perform

      expect(reupload_service).not_to have_received(:call!)
      expect(type_export_service).not_to have_received(:call!)
    end
  end
end
