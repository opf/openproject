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

describe "POST /api/v3/grids/form for Dashboard Grids", type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) do
    FactoryBot.create(:project)
  end

  let(:current_user) { allowed_user }

  shared_let(:allowed_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_dashboards manage_dashboards save_queries manage_public_queries])
  end

  shared_let(:no_save_query_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_dashboards manage_dashboards])
  end

  shared_let(:prohibited_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: [])
  end

  let(:path) { api_v3_paths.create_grid_form }
  let(:params) { {} }
  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe '#post' do
    before do
      post path, params.to_json
    end

    context 'with a valid boards scope' do
      let(:params) do
        {
          name: 'foo',
          '_links': {
            'scope': {
              'href': project_dashboards_path(project)
            }
          }
        }
      end

      it 'contains default data in the payload' do
        expected = {
          "rowCount": 1,
          "columnCount": 2,
          "widgets": [{
            "_type": "GridWidget",
            "endColumn": 2,
            "endRow": 2,
            "identifier": "work_packages_table",
            "options": {
              "name": "Work packages table",
              "queryProps": {
                "columns[]": %w(id project type subject),
                "filters": "[{\"status\":{\"operator\":\"o\",\"values\":[]}}]"
              }
            },
            "startColumn": 1,
            "startRow": 1
          }],
          "name": 'foo',
          "options": {},
          "_links": {
            "attachments": [],
            "scope": {
              'href': project_dashboards_path(project),
              "type": "text/html"
            }
          }
        }

        expect(subject.body)
          .to be_json_eql(expected.to_json)
          .at_path('_embedded/payload')
      end

      it 'has no validationErrors' do
        expect(subject.body)
          .to be_json_eql({}.to_json)
          .at_path('_embedded/validationErrors')
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.grids.to_json)
          .at_path('_links/commit/href')
      end
    end

    context 'with boards scope for which the user does not have the necessary permissions' do
      let(:current_user) { prohibited_user }
      let(:params) do
        {
          '_links': {
            'scope': {
              'href': project_dashboards_path(project)
            }
          }
        }
      end

      it 'has a validationError on scope' do
        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path('_embedded/validationErrors/scope/message')
      end
    end

    context 'with an invalid scope' do
      let(:params) do
        {
          '_links': {
            'scope': {
              'href': project_dashboards_path(project_id: project.id + 1)
            }
          }
        }
      end

      it 'has a validationError on scope' do
        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path('_embedded/validationErrors/scope/message')
      end
    end

    context 'with an unsupported widget identifier' do
      let(:params) do
        {
          name: 'foo',
          "_links": {
            "attachments": [],
            "scope": {
              'href': project_dashboards_path(project)
            }
          },
          "widgets": [
            {
              "_type": "GridWidget",
              "identifier": "bogus_identifier",
              "startRow": 1,
              "endRow": 2,
              "startColumn": 1,
              "endColumn": 2
            }
          ]
        }
      end

      it 'has a validationError on widget' do
        expect(subject.body)
          .to be_json_eql("Widgets is not set to one of the allowed values.".to_json)
          .at_path('_embedded/validationErrors/widgets/message')
      end
    end

    context 'for a user not allowed to save queries' do
      let(:current_user) { no_save_query_user }
      let(:params) do
        {
          name: 'foo',
          '_links': {
            'scope': {
              'href': project_dashboards_path(project)
            }
          }
        }
      end

      it 'contains default data in the payload that lacks the work_packages_table widget' do
        expected = {
          "rowCount": 1,
          "columnCount": 2,
          "widgets": [],
          "name": 'foo',
          "options": {},
          "_links": {
            "attachments": [],
            "scope": {
              'href': project_dashboards_path(project),
              "type": "text/html"
            }
          }
        }

        expect(subject.body)
          .to be_json_eql(expected.to_json)
          .at_path('_embedded/payload')
      end

      it 'has no validationErrors' do
        expect(subject.body)
          .to be_json_eql({}.to_json)
          .at_path('_embedded/validationErrors')
      end

      it 'has a commit link' do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.grids.to_json)
          .at_path('_links/commit/href')
      end
    end
  end
end
