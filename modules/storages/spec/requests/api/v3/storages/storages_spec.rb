#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

describe 'API v3 storages resource', type: :request, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:storage) do
    create(:storage, creator: current_user)
  end

  let(:project_storage) do
    create(:project_storage, project:, storage:)
  end

  let(:authorize_url) { 'https://example.com/authorize' }
  let(:connection_manager) { instance_double(::OAuthClients::ConnectionManager) }

  subject(:last_response) do
    get path
  end

  before do
    allow(connection_manager).to receive(:get_authorization_uri).and_return(authorize_url)
    allow(connection_manager).to receive(:authorization_state).and_return(:connected)
    allow(::OAuthClients::ConnectionManager).to receive(:new).and_return(connection_manager)
    project_storage
    login_as current_user
  end

  shared_examples_for 'successful storage response' do
    include_examples 'successful response'

    describe 'response body' do
      subject { last_response.body }

      it { is_expected.to be_json_eql('Storage'.to_json).at_path('_type') }
      it { is_expected.to be_json_eql(storage.id.to_json).at_path('id') }
    end
  end

  describe 'GET /api/v3/storages/:storage_id' do
    let(:path) { api_v3_paths.storage(storage.id) }

    context 'when user belongs to a project using the given storage' do
      let!(:project_storage) { create(:project_storage, project:, storage:) }

      it_behaves_like 'successful storage response'

      context 'if user is missing permission view_file_links' do
        let(:permissions) { [] }

        it_behaves_like 'not found'
      end

      context 'if no storage with that id exists' do
        let(:path) { api_v3_paths.storage(1337) }

        it_behaves_like 'not found'
      end
    end

    context 'when user has :manage_storages_in_project permission in any project' do
      let(:permissions) { %i(manage_storages_in_project) }

      it_behaves_like 'successful storage response'
    end

    context 'as admin' do
      let(:current_user) { create(:admin) }

      it_behaves_like 'successful storage response'
    end

    context 'when OAuth authorization server is involved' do
      shared_examples 'a storage authorization result' do |expected:, has_authorize_link:|
        subject { last_response.body }

        before do
          allow(connection_manager).to receive(:authorization_state).and_return(authorization_state)
        end

        it "returns #{expected}" do
          expect(subject).to be_json_eql(expected.to_json).at_path('_links/authorizationState/href')
        end

        it "has #{has_authorize_link ? '' : 'no'} authorize link" do
          if has_authorize_link
            expect(subject).to be_json_eql(authorize_url.to_json).at_path('_links/authorize/href')
          else
            expect(subject).not_to have_json_path('_links/authorize/href')
          end
        end
      end

      context 'when authorization succeeds and storage is connected' do
        let(:authorization_state) { :connected }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_CONNECTED,
                         has_authorize_link: false
      end

      context 'when authorization fails' do
        let(:authorization_state) { :failed_authorization }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_AUTH_FAILED,
                         has_authorize_link: true
      end

      context 'when authorization fails with an error' do
        let(:authorization_state) { :error }

        include_examples 'a storage authorization result',
                         expected: ::API::V3::Storages::URN_CONNECTION_ERROR,
                         has_authorize_link: false
      end
    end
  end
end
