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

RSpec.describe 'API v3 projects resource with filters for the linked storages',
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:user) { create(:user) }
  let(:role) { create(:role, permissions: %i[view_work_packages]) }

  # rubocop:disable RSpec/IndexedLet
  let!(:project1) { create(:project, members: { user => role }) }
  let!(:project2) { create(:project, members: { user => role }) }
  let!(:project3) { create(:project, members: { user => role }) }
  let!(:project4) { create(:project, members: { user => role }) }
  let!(:storage1) { create(:nextcloud_storage) }
  let!(:storage2) { create(:one_drive_storage) }
  let!(:storage3) { create(:one_drive_storage) }
  let!(:project_storage11) { create(:project_storage, project: project1, storage: storage1) }
  let!(:project_storage12) { create(:project_storage, project: project1, storage: storage2) }
  let!(:project_storage13) { create(:project_storage, project: project1, storage: storage3) }
  let!(:project_storage23) { create(:project_storage, project: project2, storage: storage3) }
  let!(:project_storage21) { create(:project_storage, project: project2, storage: storage1) }
  let!(:project_storage31) { create(:project_storage, project: project3, storage: storage1) }
  # rubocop:enable RSpec/IndexedLet

  subject(:response) { last_response }

  before do
    login_as user
  end

  describe 'GET /api/v3/projects' do
    let(:path) { api_v3_paths.path_for :projects, filters: }

    before do
      get path
    end

    context 'with filter for storage id' do
      let(:storage_id) { storage1.id }
      let(:filters) { [{ storageId: { operator: '=', values: [storage_id] } }] }

      it_behaves_like 'API V3 collection response', 3, 3, 'Project', 'Collection' do
        let(:elements) { [project3, project2, project1] }
      end

      context 'if a project has the storages module deactivated' do
        let(:project1) { create(:project, disable_modules: :storages) }

        it_behaves_like 'API V3 collection response', 2, 2, 'Project', 'Collection' do
          let(:elements) { [project3, project2] }
        end
      end

      context 'if the filter is set to an unknown storage id' do
        let(:storage_id) { '1337' }

        it_behaves_like 'API V3 collection response', 0, 0, 'Project', 'Collection' do
          let(:elements) { [] }
        end
      end
    end

    context 'with filter for storage url' do
      let(:storage_url) { CGI.escape(storage1.host) }
      let(:filters) { [{ storageUrl: { operator: '=', values: [storage_url] } }] }

      it_behaves_like 'API V3 collection response', 3, 3, 'Project', 'Collection' do
        let(:elements) { [project3, project2, project1] }
      end

      context 'if a project has the storages module deactivated' do
        let(:project1) { create(:project, disable_modules: :storages) }

        it_behaves_like 'API V3 collection response', 2, 2, 'Project', 'Collection' do
          let(:elements) { [project3, project2] }
        end
      end

      context 'if the filter is set to an unknown storage url' do
        let(:storage_url) { CGI.escape("https://not.my-domain.org") }

        it_behaves_like 'API V3 collection response', 0, 0, 'Project', 'Collection' do
          let(:elements) { [] }
        end
      end
    end
  end
end
