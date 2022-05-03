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

describe 'API v3 storages resource', :enable_storages, type: :request, content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:storage) do
    create(:storage, creator: current_user)
  end

  subject(:last_response) do
    get path
  end

  before do
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
      let!(:project_storage) { create(:project_storage, project: project, storage: storage) }

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

    context 'when storages module is inactive', :disable_storages do
      it_behaves_like 'not found'
    end
  end
end
