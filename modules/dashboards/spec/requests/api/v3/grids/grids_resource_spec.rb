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

describe 'API v3 Grids resource', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end
  let(:permissions) { %i[view_dashboards manage_dashboards] }
  let(:project) { FactoryBot.create(:project) }
  let(:grid) do
    FactoryBot.create(:dashboard,
                      project: project,
                      widgets: widgets)
  end
  let(:widgets) do
    [FactoryBot.create(:grid_widget,
                       identifier: 'custom_text',
                       start_column: 1,
                       end_column: 3,
                       start_row: 1,
                       end_row: 3,
                       options: {
                         text: custom_text
                       })]
  end
  let(:custom_text) { "Some text a user wrote" }

  before do
    login_as(current_user)
  end

  subject(:response) { last_response }

  describe '#get' do
    let(:path) { api_v3_paths.grid(grid.id) }

    let(:stored_grids) do
      grid
    end

    before do
      stored_grids

      get path
    end

    it 'responds with 200 OK' do
      expect(subject.status).to eq(200)
    end

    it 'sends a grid block' do
      expect(subject.body)
        .to be_json_eql('Grid'.to_json)
        .at_path('_type')
    end

    it 'identifies the url the grid is stored for' do
      expect(subject.body)
        .to be_json_eql(project_dashboards_path(project).to_json)
        .at_path('_links/scope/href')
    end

    it 'has a widget that renders custom text' do
      expect(subject.body)
        .to be_json_eql('custom_text'.to_json)
        .at_path('widgets/0/identifier')

      expect(subject.body)
        .to be_json_eql(custom_text.to_json)
        .at_path('widgets/0/options/text/raw')
    end

    context 'with the grid not existing' do
      let(:path) { api_v3_paths.grid(grid.id + 1) }

      it 'responds with 404 NOT FOUND' do
        expect(subject.status).to eql 404
      end
    end
  end

  describe '#patch' do
    let(:path) { api_v3_paths.grid(grid.id) }

    let(:stored_grids) do
      grid
    end

    let(:widget_params) { [] }

    let(:params) do
      {
        "rowCount": 10,
        "name": 'foo',
        "columnCount": 15,
        "widgets": widget_params
      }.with_indifferent_access
    end

    before do
      stored_grids

      patch path, params.to_json
    end

    context 'with an added custom_text widget' do
      let(:widget_params) do
        [
          {
            "startColumn": 1,
            "startRow": 1,
            "endColumn": 3,
            "endRow": 3,
            "identifier": "custom_text",
            "options": {
              "name": "Name for custom text widget",
              "text": {
                "format": "markdown",
                "raw": "A custom text text",
                "html": "<p>A custom text text</p>"
              }
            }
          }.with_indifferent_access
        ]
      end
      let(:widgets) { [] }

      it 'responds with 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'returns the altered grid block with the added widget' do
        expect(subject.body)
          .to be_json_eql('Grid'.to_json)
          .at_path('_type')
        expect(subject.body)
          .to be_json_eql('foo'.to_json)
          .at_path('name')
        expect(subject.body)
          .to be_json_eql(params['rowCount'].to_json)
          .at_path('rowCount')
        expect(subject.body)
          .to be_json_eql(params['widgets'][0]['identifier'].to_json)
          .at_path('widgets/0/identifier')
        expect(subject.body)
          .to be_json_eql(params['widgets'][0]['options']['text']['raw'].to_json)
          .at_path('widgets/0/options/text/raw')
        expect(subject.body)
          .to be_json_eql(params['widgets'][0]['options']['name'].to_json)
          .at_path('widgets/0/options/name')
      end

      it 'perists the changes' do
        expect(grid.reload.row_count)
          .to eql params['rowCount']
        expect(grid.reload.widgets[0].options['text'])
          .to eql params['widgets'][0]['options']['text']['raw']
        expect(grid.reload.widgets[0].options['name'])
          .to eql params['widgets'][0]['options']['name']
      end
    end
  end
end
