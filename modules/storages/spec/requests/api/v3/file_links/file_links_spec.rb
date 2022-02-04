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

describe 'API v3 file links resource', type: :request do
  include API::V3::Utilities::PathHelper

  let(:permissions) { %i(view_work_packages view_file_links) }
  let(:project) { create(:project) }

  let(:current_user) do
    create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:work_package) do
    create(:work_package, author: current_user, project: project)
  end

  let(:storage) do
    create(:storage, creator: current_user)
  end

  let(:file_link) do
    create(:file_link, creator: current_user, container: work_package, storage: storage)
  end

  subject(:response) { last_response }

  before do
    login_as current_user
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links' do
    let(:path) { api_v3_paths.file_links(work_package.id) }

    before do
      file_link
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 200
    end

    context 'if user has not sufficient permissions' do
      let(:permissions) { %i(view_work_packages) }

      it_behaves_like 'API V3 collection response', 0, 0, 'FileLink', 'Collection' do
        let(:elements) { [] }
      end
    end
  end

  describe 'POST /api/v3/work_packages/:work_package_id/file_links' do
    let(:path) { api_v3_paths.file_links(work_package.id) }
    let(:params) { {} }

    before do
      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns not implemented' do
      expect(subject.status).to be 501
    end
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(work_package.id, file_link.id) }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 200
    end

    context 'if user has not sufficient permissions' do
      let(:permissions) { %i(view_work_packages) }

      it_behaves_like 'not found'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(work_package.id, 1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'DELETE /api/v3/work_packages/:work_package_id/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(work_package.id, file_link.id) }
    let(:permissions) { %i(view_work_packages view_file_links manage_file_links) }

    before do
      header 'Content-Type', 'application/json'
      delete path
    end

    it 'is successful' do
      expect(subject.status).to be 204
    end

    context 'if user has no view permissions' do
      let(:permissions) { %i(view_work_packages) }

      it_behaves_like 'not found'
    end

    context 'if user has no manage permissions' do
      let(:permissions) { %i(view_work_packages view_file_links) }

      it_behaves_like 'unauthorized access'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(work_package.id, 1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links/:file_link_id/download' do
    let(:path) { api_v3_paths.file_link_download(work_package.id, file_link.id) }

    before do
      get path
    end

    it 'returns not implemented' do
      expect(subject.status).to be 501
    end
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links/:file_link_id/open' do
    let(:path) { api_v3_paths.file_link_open(work_package.id, file_link.id) }

    before do
      get path
    end

    it 'returns not implemented' do
      expect(subject.status).to be 501
    end
  end
end
