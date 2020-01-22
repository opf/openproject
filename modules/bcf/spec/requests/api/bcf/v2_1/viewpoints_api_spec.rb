#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
require 'rack/test'

require_relative './shared_responses'

describe 'BCF 2.1 viewpoints resource', type: :request, content_type: :json, with_mail: false do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: [:bcf])
  end

  shared_let(:view_only_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: [:view_linked_issues])
  end

  shared_let(:create_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_linked_issues manage_bcf])
  end

  shared_let(:non_member_user) do
    FactoryBot.create(:user)
  end

  shared_let(:work_package) do
    User.execute_as create_user do
      FactoryBot.create(:work_package, project: project)
    end
  end
  let(:bcf_issue) { FactoryBot.create(:bcf_issue_with_viewpoint, work_package: work_package) }

  let(:viewpoint) { bcf_issue.viewpoints.first }
  let(:viewpoint_json) { viewpoint.json_viewpoint }
  subject(:response) { last_response }

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:topic/viewpoints' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) { [viewpoint_json] }
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end
  end

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:uuid/viewpoints/:uuid' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints/#{viewpoint.uuid}" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) { viewpoint_json }
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'invalid uuid' do
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/0/viewpoints" }

      it_behaves_like 'bcf api not found response'
    end
  end

  %w[selection coloring visibility].each do |section|
    describe "GET /api/bcf/2.1/projects/:project_id/topics/:uuid/viewpoints/:uuid/#{section}" do
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints/#{viewpoint.uuid}/#{section}" }
      let(:current_user) { view_only_user }

      before do
        login_as(current_user)
        bcf_issue
        get path
      end

      it_behaves_like 'bcf api successful response' do
        let(:expected_body) do
          { section => viewpoint_json.dig('components', section) }
        end
      end
    end
  end

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:uuid/viewpoints/:uuid/snapshot' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints/#{viewpoint.uuid}/snapshot" }
    let(:current_user) { view_only_user }

    context 'when snapshot present' do
      before do
        login_as(current_user)
        get path
      end

      it 'responds with the attachment' do
        expect(subject.status).to eq 200
        expect(subject.headers['Content-Type']).to eq 'image/jpeg'
      end
    end

    context 'when snapshot not present' do
      before do
        login_as(current_user)
        viewpoint.snapshot.destroy
        get path
      end

      it_behaves_like 'bcf api not found response'
    end
  end

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:uuid/viewpoints/:uuid/bitmaps' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints/#{viewpoint.uuid}/bitmaps" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      get path
    end

    it_behaves_like 'bcf api not implemented response' do
      let(:expected_message) { 'Bitmaps are not yet implemented.' }
    end
  end

  describe 'POST /api/bcf/2.1/projects/:project_id/topics/:topic/viewpoints' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}/viewpoints" }
    let(:current_user) { create_user }
    let(:params) do
      FactoryBot
        .attributes_for(:bcf_viewpoint)[:json_viewpoint]
        .merge(
          "snapshot" =>
            {
              "snapshot_type" => "png",
              "snapshot_data" => "SGVsbG8gV29ybGQh"
            }
        ).except('bitmaps', 'guid')
    end

    before do
      login_as(current_user)
      post path, params.to_json
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        new_viewpoint = Bcf::Viewpoint.last

        params
          .merge(guid: new_viewpoint.uuid)
      end

      let(:expected_status) { 201 }
    end

    it 'creates the viewpoint with an attachment for the snapshot' do
      expect(Bcf::Viewpoint.count)
        .to eql 2

      expect(Bcf::Viewpoint.last.attachments.count)
        .to eql 1
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'lacking manage_bcf permission' do
      let(:current_user) { view_only_user }

      it_behaves_like 'bcf api not allowed response'
    end

    context 'providing an invalid viewpoint json by having an invalid snapshot type' do
      let(:params) do
        FactoryBot
          .attributes_for(:bcf_viewpoint)[:json_viewpoint]
          .merge(
            "snapshot" =>
              {
                "snapshot_type" => "tiff",
                "snapshot_data" => "SGVsbG8gV29ybGQh"
              }
          ).except('bitmaps')
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) { I18n.t('activerecord.errors.models.bcf/viewpoint.snapshot_type_unsupported') }
      end
    end

    context 'providing an invalid viewpoint json by not having snapshot_data' do
      let(:params) do
        FactoryBot
          .attributes_for(:bcf_viewpoint)[:json_viewpoint]
          .merge(
            "snapshot" =>
              {
                "snapshot_type" => "jpg"
              }
          ).except('bitmaps')
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) { I18n.t('activerecord.errors.models.bcf/viewpoint.snapshot_data_blank') }
      end
    end

    context 'providing an invalid viewpoint json by writing bitmaps and having a string for the integer' do
      let(:params) do
        FactoryBot
          .attributes_for(:bcf_viewpoint)[:json_viewpoint]
          .merge('index' => 'some invalid index')
      end

      it_behaves_like 'bcf api unprocessable response' do
        let(:message) do
          [I18n.t('api_v3.errors.multiple_errors'),
           I18n.t('activerecord.errors.models.bcf/viewpoint.index_not_integer'),
           I18n.t('activerecord.errors.models.bcf/viewpoint.bitmaps_not_writable')].join(" ")
        end
      end
    end
  end
end
