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

  let(:work_package) { create(:work_package, author: current_user, project: project) }
  let(:another_work_package) { create(:work_package, author: current_user, project: project) }

  let(:storage) { create(:storage, creator: current_user) }
  let(:another_storage) { create(:storage, creator: current_user) }

  let!(:project_storage) { create(:project_storage, project: project, storage: storage) }

  let(:file_link) do
    create(:file_link, creator: current_user, container: work_package, storage: storage)
  end
  let(:another_file_link) do
    create(:file_link, creator: current_user, container: another_work_package, storage: storage)
  end

  subject(:response) { last_response }

  before do
    login_as current_user
  end

  describe 'GET /api/v3/work_packages/:work_package_id/file_links' do
    let(:path) { api_v3_paths.file_links(work_package.id) }

    before do
      file_link
      another_file_link
      get path
    end

    it_behaves_like 'API V3 collection response', 1, 1, 'FileLink', 'Collection' do
      let(:elements) { [file_link] }
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
    let(:permissions) { %i(view_work_packages manage_file_links) }
    let(:storage_url1) { storage.host }
    let(:storage_url2) { storage.host }
    let(:params) do
      {
        _type: "Collection",
        _embedded: {
          elements: [
            {
              originData: {
                id: 5503,
                name: "logo.png",
                mimeType: "image/png",
                createdAt: "2021-12-19T09:42:10.170Z",
                lastModifiedAt: "2021-12-20T14:00:13.987Z",
                createdByName: "Luke Skywalker",
                lastModifiedByName: "Anakin Skywalker"
              },
              _links: {
                storageUrl: {
                  href: storage_url1
                }
              }
            },
            {
              originData: {
                id: 5514,
                name: "plans.md",
                mimeType: "text/markdown",
                createdAt: "2021-12-14T09:01:23.456Z",
                lastModifiedAt: "2021-12-14T09:01:23.456Z",
                createdByName: "Yoda",
                lastModifiedByName: "Yoda"
              },
              _links: {
                storageUrl: {
                  href: storage_url2
                }
              }
            }
          ]
        }
      }
    end

    before do
      header 'Content-Type', 'application/json'
      post path, params.to_json
    end

    it_behaves_like 'API V3 collection response', 2, 2, 'FileLink' do
      let(:elements) { Storages::FileLink.all.order(id: :asc) }
      let(:expected_status_code) { 201 }
    end

    context 'when storage host is invalid' do
      context 'when unknown host' do
        let(:storage_url1) { 'https://invalid.host.org/' }

        it_behaves_like 'constraint violation' do
          let(:message) { 'Storage does not exist' }
        end
      end

      context 'when nil' do
        let(:storage_url1) { nil }

        it_behaves_like 'constraint violation' do
          let(:message) { "Storage can't be blank." }
        end
      end

      context 'when empty' do
        let(:storage_url1) { "" }

        it_behaves_like 'constraint violation' do
          let(:message) { "Storage can't be blank." }
        end
      end

      context 'when not linked to the project of the work package' do
        let(:storage_url1) { another_storage.host }

        it_behaves_like 'constraint violation' do
          let(:message) { 'Storage is not linked to project' }
        end
      end
    end

    context 'when no _embedded/elements in given json' do
      let(:params) do
        {}
      end

      it_behaves_like 'missing property', I18n.t('api_v3.errors.missing_property', property: '_embedded/elements')
    end

    context 'when _embedded/elements is empty' do
      let(:params) do
        { _embedded: { elements: [] } }
      end

      it_behaves_like 'missing property', I18n.t('api_v3.errors.missing_property', property: '_embedded/elements')
    end

    context 'when _embedded/elements is not an array' do
      let(:params) do
        { _embedded: { elements: 42 } }
      end

      it_behaves_like 'format error',
                      I18n.t('api_v3.errors.invalid_format',
                             property: '_embedded/elements',
                             expected_format: 'Array',
                             actual: 'Integer')
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context "when more than #{API::V3::FileLinks::ParseCreateParamsService::MAX_ELEMENTS} embedded elements" do
      let(:max) { API::V3::FileLinks::ParseCreateParamsService::MAX_ELEMENTS }
      let(:too_many) { max + 1 }
      let(:params) do
        {
          _type: "Collection",
          _embedded: {
            elements: 1.upto(too_many).map do |id|
              {
                originData: {
                  id: id,
                  name: "logo#{id}.png",
                  mimeType: "image/png",
                  createdAt: "2021-12-19T09:42:10.170Z",
                  lastModifiedAt: "2021-12-20T14:00:13.987Z",
                  createdByName: "Luke Skywalker",
                  lastModifiedByName: "Anakin Skywalker"
                },
                _links: {
                  storageUrl: {
                    href: storage_url1
                  }
                }
              }
            end
          }
        }
      end

      it_behaves_like 'constraint violation' do
        let(:message) { "Too many elements created at once. Expected #{max} at most, got #{too_many}." }
      end
    end
    # rubocop:enable RSpec/MultipleMemoizedHelpers
  end

  describe 'GET /api/v3/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(file_link.id) }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 200
    end

    context 'if user has not sufficient permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'DELETE /api/v3/file_links/:file_link_id' do
    let(:path) { api_v3_paths.file_link(file_link.id) }
    let(:permissions) { %i(view_file_links manage_file_links) }

    before do
      header 'Content-Type', 'application/json'
      delete path
    end

    it 'is successful' do
      expect(subject.status).to be 204
      expect(::Storages::FileLink.exists?(id: file_link.id)).to be false
    end

    context 'if user has no view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if user has no manage permissions' do
      let(:permissions) { %i(view_file_links) }

      it_behaves_like 'unauthorized access'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end
  end

  describe 'GET /api/v3/file_links/:file_link_id/open' do
    let(:path) { api_v3_paths.file_link_open(file_link.id) }

    before do
      get path
    end

    it 'is successful' do
      expect(subject.status).to be 303
    end

    context 'if user has no view permissions' do
      let(:permissions) { [] }

      it_behaves_like 'not found'
    end

    context 'if no storage with that id exists' do
      let(:path) { api_v3_paths.file_link(1337) }

      it_behaves_like 'not found'
    end
  end
end
