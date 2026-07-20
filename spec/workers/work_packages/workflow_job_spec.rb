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

  before do
    allow(Projects::CreationWizard::ReuploadArtifactOnStatusChangesService)
      .to receive(:new).and_return(reupload_service)
    allow(WorkPackages::TypeArtefactExport::ExportOnStatusChangeService)
      .to receive(:new).and_return(type_export_service)
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
