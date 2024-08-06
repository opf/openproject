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

RSpec.describe Bim::Bcf::IssuesController do
  let(:manage_bcf_role) do
    create(:project_role,
           permissions: %i[manage_bcf view_linked_issues view_work_packages add_work_packages edit_work_packages])
  end
  let(:collaborator_role) do
    create(:project_role,
           permissions: %i[view_linked_issues view_work_packages add_work_packages edit_work_packages])
  end
  let(:bcf_manager) { create(:user, firstname: "BCF Manager") }
  let(:collaborator) { create(:user) }

  let(:non_member) { create(:user) }
  let(:project) do
    create(:project, enabled_module_names: %w[bim], identifier: "bim_project")
  end
  let(:member) do
    create(:member,
           project:,
           user: collaborator,
           roles: [collaborator_role])
  end
  let(:bcf_manager_member) do
    create(:member,
           project:,
           user: bcf_manager,
           roles: [manage_bcf_role])
  end

  before do
    bcf_manager_member
    member
    login_as(bcf_manager)
  end

  shared_examples_for "check permissions" do
    context "without sufficient permissions" do
      before { action }

      context "not member of project" do
        let(:bcf_manager_member) {}

        it 'returns "not authorized"' do
          expect(response).not_to be_successful
        end
      end

      context "no manage_bcf permission" do
        let(:bcf_manager_member) do
          create(:member,
                 project:,
                 user: bcf_manager,
                 roles: [collaborator_role])
        end

        it 'returns "not authorized"' do
          expect(response).not_to be_successful
        end
      end
    end
  end

  describe "#prepare_import" do
    let(:params) do
      {
        project_id: project.identifier.to_s,
        bcf_file: file
      }
    end
    let(:action) do
      post :prepare_import, params:
    end

    context "with valid BCF file" do
      let(:filename) { "MaximumInformation.bcf" }
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("modules/bim/spec/fixtures/files/#{filename}").to_s,
          "application/zip"
        )
      end

      it "is successful" do
        expect { action }.to change { Attachment.count }.by(1)
        expect(response).to be_successful
      end

      it_behaves_like "check permissions"
    end

    context "with invalid BCF file" do
      let(:file) { FileHelpers.mock_uploaded_file }

      it "redirects back to where we started from" do
        expect { action }.not_to change { Attachment.count }
        expect(response).to redirect_to "/projects/bim_project/issues/upload"
      end
    end
  end

  describe "#configure_import" do
    let(:action) do
      post :configure_import, params: { project_id: project.identifier.to_s }
    end

    context "with valid BCF file" do
      let(:filename) { "MaximumInformation.bcf" }
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("modules/bim/spec/fixtures/files/#{filename}").to_s,
          "application/octet-stream"
        )
      end

      before do
        allow_any_instance_of(Attachment).to receive(:diskfile).and_return(file)
        allow(Attachment).to receive(:find_by).and_return(Attachment.new)
      end

      it "is successful" do
        expect { action }.not_to change { Attachment.count }
        expect(response).to be_successful
      end

      it_behaves_like "check permissions"
    end
  end

  describe "#perform_import" do
    let(:action) do
      post :perform_import, params: { project_id: project.identifier.to_s }
    end

    context "with valid BCF file" do
      let(:filename) { "MaximumInformation.bcf" }
      let(:file) do
        Rack::Test::UploadedFile.new(
          Rails.root.join("modules/bim/spec/fixtures/files/#{filename}").to_s,
          "application/octet-stream"
        )
      end

      before do
        allow_any_instance_of(Attachment).to receive(:diskfile).and_return(file)
        allow(Attachment).to receive(:find_by).and_return(Attachment.new)
      end

      it "is successful" do
        expect { action }.not_to change { Attachment.count }
        expect(response).to be_successful
      end

      it_behaves_like "check permissions"
    end
  end
end
