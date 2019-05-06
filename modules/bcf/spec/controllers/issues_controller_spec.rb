#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::Bcf::IssuesController, type: :controller do
  let(:manage_bcf_role) { FactoryBot.create(:role, permissions: %i[manage_bcf view_linked_issues view_work_packages]) }
  let(:collaborator_role) {FactoryBot.create(:role, permissions: %i[view_linked_issues view_work_packages])}
  let(:bcf_manager) { FactoryBot.create(:user) }
  let(:collaborator) { FactoryBot.create(:user) }

  let(:non_member) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project,
                                    identifier: 'bim_project'
  ) }
  let(:member) {
    FactoryBot.create(:member,
                      project: project,
                      user: collaborator,
                      roles: [collaborator_role])
  }
  let(:bcf_manager_member) {
    FactoryBot.create(:member,
                      project: project,
                      user: bcf_manager,
                      roles: [manage_bcf_role])
  }
  before do
    bcf_manager_member
    member
    allow(User).to receive(:current).and_return(bcf_manager)
  end

  describe '#prepare_import' do
    let(:params) { { project_id: project.identifier.to_s,
                     bcf_file: file} }

    let(:action) do
      post :prepare_import, params: params
    end

    context 'with valid BCF file' do
      let(:filename) { 'MaximumInformation.bcf' }
      let(:file) { Rack::Test::UploadedFile.new(
        File.join(Rails.root, "modules/bcf/spec/fixtures/files/#{filename}"),
        'application/octet-stream') }

      it 'should be successful' do
        expect { action }.to change { Attachment.count }.by(1)
        expect(response).to be_successful
      end
    end

    context 'with invalid BCF file' do
      let(:file) { FileHelpers.mock_uploaded_file }

      it 'should redirect back to where we started from' do
        expect { action }.to change { Attachment.count }.by(1)
        expect(response).to redirect_to '/projects/bim_project/issues'
      end
    end
  end
end
