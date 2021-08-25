#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'

describe 'API v3 Work package resource',
         type: :request,
         content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:work_package) do
    FactoryBot.create(:work_package,
                      project_id: project.id,
                      description: 'lorem ipsum')
  end
  let(:project) do
    FactoryBot.create(:project, identifier: 'test_project', public: false)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }

  current_user do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end

  describe 'GET /api/v3/work_packages' do
    subject { last_response }

    let(:path) { api_v3_paths.work_packages }
    let(:other_work_package) { FactoryBot.create(:work_package) }
    let(:work_packages) { [work_package, other_work_package] }

    before do
      work_packages
      get path
    end

    it 'succeeds' do
      expect(subject.status).to eql 200
    end

    it 'returns visible work packages' do
      expect(subject.body).to be_json_eql(1.to_json).at_path('total')
    end

    it 'embedds the work package schemas' do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.work_package_schema(project.id, work_package.type.id).to_json)
              .at_path('_embedded/schemas/_embedded/elements/0/_links/self/href')
    end

    context 'with filtering by typeahead' do
      let(:path) { api_v3_paths.path_for :work_packages, filters: filters }
      let(:filters) do
        [
          {
            "typeahead": {
              "operator": "**",
              "values": "lorem ipsum"
            }
          }
        ]
      end

      let(:lorem_ipsum_work_package) { FactoryBot.create(:work_package, project: project, subject: "lorem ipsum") }
      let(:lorem_project) { FactoryBot.create(:project, members: { current_user => role }, name: "lorem other") }
      let(:ipsum_work_package) { FactoryBot.create(:work_package, subject: "other ipsum", project: lorem_project) }
      let(:other_lorem_work_package) { FactoryBot.create(:work_package, subject: "lorem", project: lorem_project) }
      let(:work_packages) { [work_package, lorem_ipsum_work_package, ipsum_work_package, other_lorem_work_package] }

      it_behaves_like 'API V3 collection response', 2, 2, 'WorkPackage', 'WorkPackageCollection' do
        let(:elements) { [lorem_ipsum_work_package, ipsum_work_package] }
      end
    end

    context 'with a user not seeing any work packages' do
      include_context 'with non-member permissions from non_member_permissions'
      let(:current_user) { FactoryBot.create(:user) }
      let(:non_member_permissions) { [:view_work_packages] }

      it 'succeeds' do
        expect(subject.status).to eql 200
      end

      it 'returns no work packages' do
        expect(subject.body).to be_json_eql(0.to_json).at_path('total')
      end

      context 'with the user not allowed to see work packages in general' do
        let(:non_member_permissions) { [] }

        it_behaves_like 'unauthorized access'
      end
    end

    describe 'encoded query props' do
      let(:props) do
        eprops = {
          filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
          sortBy: [%w(id asc)].to_json,
          pageSize: 1
        }.to_json

        {
          eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
        }.to_query
      end
      let(:path) { "#{api_v3_paths.work_packages}?#{props}" }
      let(:other_visible_work_package) do
        FactoryBot.create(:work_package,
                          project: project)
      end
      let(:another_visible_work_package) do
        FactoryBot.create(:work_package,
                          project: project)
      end

      let(:work_packages) { [work_package, other_work_package, other_visible_work_package, another_visible_work_package] }

      it 'succeeds' do
        expect(subject.status)
          .to eql 200
      end

      it 'returns visible and filtered work packages' do
        expect(subject.body)
          .to be_json_eql(2.to_json)
                .at_path('total')

        # because of the page size
        expect(subject.body)
          .to be_json_eql(1.to_json)
                .at_path('count')

        expect(subject.body)
          .to be_json_eql(work_package.id.to_json)
                .at_path('_embedded/elements/0/id')
      end

      context 'without zlibbed' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Base64.encode64(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non json encoded' do
        let(:props) do
          eprops = "some non json string"

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non base64 encoded' do
        let(:props) do
          eprops = {
            filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
            sortBy: [%w(id asc)].to_json,
            pageSize: 1
          }.to_json

          {
            eprops: Zlib::Deflate.deflate(eprops)
          }.to_query
        end

        it_behaves_like 'param validation error'
      end

      context 'non hash' do
        let(:props) do
          eprops = [{
                      filters: [{ id: { operator: '=', values: [work_package.id.to_s, other_visible_work_package.id.to_s] } }].to_json,
                      sortBy: [%w(id asc)].to_json,
                      pageSize: 1
                    }].to_json

          {
            eprops: Base64.encode64(Zlib::Deflate.deflate(eprops))
          }.to_query
        end

        it_behaves_like 'param validation error'
      end
    end
  end
end
