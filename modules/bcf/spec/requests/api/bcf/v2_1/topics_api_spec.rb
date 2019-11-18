#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2019 the OpenProject Foundation (OPF)
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

describe 'BCF 2.1 topics resource', type: :request, content_type: :json, with_mail: false do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:view_only_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: [:view_linked_issues])
  end
  let(:only_member_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: [])
  end
  let(:non_member_user) do
    FactoryBot.create(:user)
  end

  let(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: [:bcf])
  end
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:bcf_issue) { FactoryBot.create(:bcf_issue, work_package: work_package) }

  subject(:response) { last_response }

  describe 'GET /api/bcf/2.1/projects/:project_id/topics' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        [
          {
            "assigned_to": "andy@example.com",
            "creation_author": "mike@example.com",
            "creation_date": "2015-06-21T12:00:00Z",
            "description": "This is a topic with all information present.",
            "due_date": nil,
            guid: bcf_issue.uuid,
            "index": "0",
            "labels": [
              "Structural",
              "IT Development"
            ],
            "modified_author": "michelle@example.com",
            "modified_date": "2015-06-21T14:22:47Z",
            "reference_links": [
              api_v3_paths.work_package(work_package.id)
            ],
            "stage": "Construction start",
            "title": "Maximum Content",
            "topic_status": "Open",
            "topic_type": "Structural"
          }
        ]
      end
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'lacking permission to see linked issues' do
      let(:current_user) { only_member_user }

      it_behaves_like 'bcf api not allowed response'
    end
  end

  describe 'GET /api/bcf/2.1/projects/:project_id/topics/:uuid' do
    let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/#{bcf_issue.uuid}" }
    let(:current_user) { view_only_user }

    before do
      login_as(current_user)
      bcf_issue
      get path
    end

    it_behaves_like 'bcf api successful response' do
      let(:expected_body) do
        {
          "assigned_to": "andy@example.com",
          "creation_author": "mike@example.com",
          "creation_date": "2015-06-21T12:00:00Z",
          "description": "This is a topic with all information present.",
          "due_date": nil,
          guid: bcf_issue.uuid,
          "index": "0",
          "labels": [
            "Structural",
            "IT Development"
          ],
          "modified_author": "michelle@example.com",
          "modified_date": "2015-06-21T14:22:47Z",
          "reference_links": [
            api_v3_paths.work_package(work_package.id)
          ],
          "stage": "Construction start",
          "title": "Maximum Content",
          "topic_status": "Open",
          "topic_type": "Structural"
        }
      end
    end

    context 'lacking permission to see project' do
      let(:current_user) { non_member_user }

      it_behaves_like 'bcf api not found response'
    end

    context 'invalid uuid' do
      let(:path) { "/api/bcf/2.1/projects/#{project.id}/topics/0" }

      it_behaves_like 'bcf api not found response'
    end

    context 'lacking permission to see linked issues' do
      let(:current_user) { only_member_user }

      it_behaves_like 'bcf api not allowed response'
    end
  end
end
