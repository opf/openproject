#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

RSpec.describe 'API v3 project storages resource', content_type: :json, webmock: true do
  include API::V3::Utilities::PathHelper

  let(:view_permissions) { %i(view_work_packages view_file_links) }

  # rubocop:disable RSpec/IndexedLet
  let(:project1) { create(:project) }
  let(:project2) { create(:project) }
  let(:project3) { create(:project) }
  let(:storage1) { create(:storage) }
  let(:storage2) { create(:storage) }
  let(:storage3) { create(:storage) }
  let!(:project_storage11) { create(:project_storage, project: project1, storage: storage1) }
  let!(:project_storage12) { create(:project_storage, project: project1, storage: storage2) }
  let!(:project_storage13) { create(:project_storage, project: project1, storage: storage3) }
  let!(:project_storage23) { create(:project_storage, project: project2, storage: storage3) }
  let!(:project_storage21) { create(:project_storage, project: project2, storage: storage1) }
  let!(:project_storage31) { create(:project_storage, project: project3, storage: storage1) }
  # rubocop:enable RSpec/IndexedLet

  subject(:last_response) do
    get path
  end

  before do
    login_as current_user
  end

  describe 'GET /api/v3/project_storages' do
    let(:path) { api_v3_paths.project_storages }

    context 'as admin' do
      let(:current_user) { create(:admin) }

      subject { last_response.body }

      describe 'gets full project storage collection' do
        it_behaves_like 'API V3 collection response', 6, 6, 'ProjectStorage', 'Collection' do
          let(:elements) do
            [
              project_storage31,
              project_storage21,
              project_storage23,
              project_storage13,
              project_storage12,
              project_storage11
            ]
          end
        end
      end

      context 'with project filter' do
        let(:filters) { [{ projectId: { operator: "=", values: [project_id] } }] }
        let(:path) { api_v3_paths.path_for(:project_storages, filters:) }

        describe 'gets all project storages of the filtered project' do
          let(:project_id) { project2.id }

          it_behaves_like 'API V3 collection response', 2, 2, 'ProjectStorage', 'Collection' do
            let(:elements) { [project_storage21, project_storage23] }
          end
        end

        context 'with invalid project id' do
          let(:project_id) { '1337' }

          it_behaves_like 'invalid filters'
        end

        context 'with project id of project with no storages' do
          let(:project) { create(:project) }
          let(:project_id) { project.id }

          it_behaves_like 'API V3 collection response', 0, 0, 'ProjectStorage', 'Collection' do
            let(:elements) { [] }
          end
        end
      end

      context 'with storage filter' do
        let(:filters) { [{ storageId: { operator: "=", values: [storage_id] } }] }
        let(:path) { api_v3_paths.path_for(:project_storages, filters:) }

        describe 'gets all project storages of the filtered project' do
          let(:storage_id) { storage3.id }

          it_behaves_like 'API V3 collection response', 2, 2, 'ProjectStorage', 'Collection' do
            let(:elements) { [project_storage23, project_storage13] }
          end
        end

        context 'with invalid storage id' do
          let(:storage_id) { '1337' }

          it_behaves_like 'invalid filters'
        end

        context 'with storage id of storage with no linked projects' do
          let(:storage) { create(:storage) }
          let(:storage_id) { storage.id }

          it_behaves_like 'API V3 collection response', 0, 0, 'ProjectStorage', 'Collection' do
            let(:elements) { [] }
          end
        end
      end
    end

    context 'as user with permissions' do
      let(:current_user) do
        create(:user, member_in_projects: [project1, project3], member_with_permissions: view_permissions)
      end

      it_behaves_like 'API V3 collection response', 4, 4, 'ProjectStorage', 'Collection' do
        let(:elements) do
          [
            project_storage31,
            project_storage13,
            project_storage12,
            project_storage11
          ]
        end
      end
    end

    context 'as user without permissions' do
      let(:current_user) do
        create(:user, member_in_projects: [project1, project2, project3], member_with_permissions: [])
      end

      it_behaves_like 'API V3 collection response', 0, 0, 'ProjectStorage', 'Collection' do
        let(:elements) { [] }
      end
    end
  end

  describe 'GET /api/v3/project_storages/:id' do
    let(:project_storage) do
      create(:project_storage,
             project: project3,
             storage: storage3,
             project_folder_id: '1337',
             project_folder_mode: 'manual')
    end
    let(:project_storage_id) { project_storage.id }
    let(:path) { api_v3_paths.project_storage(project_storage_id) }
    let(:current_user) do
      create(:user, member_in_project: project3, member_with_permissions: view_permissions)
    end

    subject { last_response.body }

    it_behaves_like 'successful response'

    it { is_expected.to be_json_eql(api_v3_paths.storage_file(storage3.id, '1337').to_json).at_path('_links/projectFolder/href') }

    it { is_expected.to be_json_eql('manual'.to_json).at_path('projectFolderMode') }

    context 'if user has permission to see file storages in project' do
      let(:current_user) do
        create(:user, member_in_project: project3, member_with_permissions: [])
      end

      it_behaves_like 'not found'
    end

    context 'if user is not member in related project' do
      let(:project_storage_id) { project_storage11.id }

      it_behaves_like 'not found'
    end

    context 'if project storage does not exists' do
      let(:project_storage_id) { '1337' }

      it_behaves_like 'not found'
    end
  end
end
