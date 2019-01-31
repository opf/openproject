#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'API v3 Grids resource for Board Grids', type: :request, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:manage_boards_project) { FactoryBot.create(:project) }
  shared_let(:view_boards_project) { FactoryBot.create(:project) }
  shared_let(:other_project) { FactoryBot.create(:project) }
  shared_let(:view_boards_role) { FactoryBot.create(:role, permissions: [:view_boards]) }
  shared_let(:manage_boards_role) { FactoryBot.create(:role, permissions: [:manage_boards]) }
  shared_let(:other_role) { FactoryBot.create(:role, permissions: []) }
  shared_let(:current_user) do
    FactoryBot.create(:user).tap do |user|
      FactoryBot.create(:member, user: user, project: manage_boards_project, roles: [manage_boards_role])
      FactoryBot.create(:member, user: user, project: view_boards_project, roles: [view_boards_role])
      FactoryBot.create(:member, user: user, project: other_project, roles: [other_role])
    end
  end

  let(:manage_boards_grid) do
    grid = Boards::Grid.new_default(project: manage_boards_project)
    grid.save!
    grid
  end
  let(:view_boards_grid) do
    grid = Boards::Grid.new_default(project: view_boards_project)
    grid.save!
    grid
  end
  let(:other_board_grid) do
    grid = Boards::Grid.new_default(project: other_project)
    grid.save!
    grid
  end

  before do
    login_as(current_user)
  end

  subject(:response) { last_response }

  describe '#get INDEX' do
    let(:path) { api_v3_paths.grids }

    let(:stored_grids) do
      manage_boards_grid
      other_board_grid
    end

    before do
      stored_grids

      get path
    end

    it 'responds with 200 OK' do
      expect(subject.status).to eq(200)
    end

    it 'sends a collection of grids but only those visible to the current user' do
      expect(subject.body)
        .to be_json_eql('Collection'.to_json)
        .at_path('_type')

      expect(subject.body)
        .to be_json_eql('Grid'.to_json)
        .at_path('_embedded/elements/0/_type')

      expect(subject.body)
        .to be_json_eql(1.to_json)
        .at_path('total')
    end

    context 'with a filter on the scope attribute for all boards of a project' do
      # The user would be able to see both boards
      shared_let(:other_role) { FactoryBot.create(:role, permissions: [:view_boards]) }

      let(:path) do
        filter = [{ 'scope' =>
                      {
                        'operator' => '=',
                        'values' => [boards_project_path(manage_boards_project)]
                      } }]

        "#{api_v3_paths.grids}?#{{ filters: filter.to_json }.to_query}"
      end

      it 'responds with 200 OK' do
        expect(subject.status).to eq(200)
      end

      it 'sends only the board of the project' do
        expect(subject.body)
          .to be_json_eql('Collection'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql('Grid'.to_json)
          .at_path('_embedded/elements/0/_type')

        expect(subject.body)
          .to be_json_eql(1.to_json)
          .at_path('total')

        expect(subject.body)
          .to be_json_eql(manage_boards_grid.id.to_json)
          .at_path('_embedded/elements/0/id')
      end
    end
  end

  describe '#get' do
    let(:path) { api_v3_paths.grid(manage_boards_grid.id) }

    let(:stored_grids) do
      manage_boards_grid
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
        .to be_json_eql(project_boards_path(manage_boards_project).to_json)
        .at_path('_links/scope/href')
    end

    context 'with the scope not existing' do
      let(:path) { api_v3_paths.grid(5) }

      it 'responds with 404 NOT FOUND' do
        expect(subject.status).to eql 404
      end
    end

    context 'when lacking permission to see the grid' do
      let(:stored_grids) do
        manage_boards_grid
        other_board_grid
      end

      let(:path) { api_v3_paths.grid(other_board_grid.id) }

      it 'responds with 404 NOT FOUND' do
        expect(subject.status).to eql 404
      end
    end
  end

  describe '#patch' do
    let(:path) { api_v3_paths.grid(manage_boards_grid.id) }

    let(:params) do
      {
        "rowCount": 10,
        "columnCount": 15,
        "widgets": [{
          "identifier": "work_package_query",
          "startRow": 4,
          "endRow": 8,
          "startColumn": 2,
          "endColumn": 5
        }]
      }.with_indifferent_access
    end

    let(:stored_grids) do
      manage_boards_grid
    end

    before do
      stored_grids

      patch path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'responds with 200 OK' do
      expect(subject.status).to eq(200)
    end

    it 'returns the altered grid block' do
      expect(subject.body)
        .to be_json_eql('Grid'.to_json)
        .at_path('_type')
      expect(subject.body)
        .to be_json_eql(params['rowCount'].to_json)
        .at_path('rowCount')
      expect(subject.body)
        .to be_json_eql(params['widgets'][0]['identifier'].to_json)
        .at_path('widgets/0/identifier')
    end

    it 'perists the changes' do
      expect(manage_boards_grid.reload.row_count)
        .to eql params['rowCount']
    end

    context 'with invalid params' do
      let(:params) do
        {
          "rowCount": -5,
          "columnCount": 15,
          "widgets": [{
            "identifier": "work_package_query",
            "startRow": 4,
            "endRow": 8,
            "startColumn": 2,
            "endColumn": 5
          }]
        }.with_indifferent_access
      end

      it 'responds with 422 and mentions the error' do
        expect(subject.status).to eq 422

        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("Widgets is outside of the grid.".to_json)
          .at_path('_embedded/errors/0/message')

        expect(subject.body)
          .to be_json_eql("Number of rows must be greater than 0.".to_json)
          .at_path('_embedded/errors/1/message')
      end

      it 'does not persist the changes to widgets' do
        expect(manage_boards_grid.reload.widgets.count)
          .to eql Boards::Grid.new_default(project: manage_boards_project, user: current_user).widgets.size
      end
    end

    context 'with a scope param' do
      let(:params) do
        {
          "_links": {
            "scope": {
              "href": ''
            }
          }
        }.with_indifferent_access
      end

      it 'responds with 422 and mentions the error' do
        expect(subject.status).to eq 422

        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("You must not write a read-only attribute.".to_json)
          .at_path('message')

        expect(subject.body)
          .to be_json_eql("scope".to_json)
          .at_path('_embedded/details/attribute')
      end
    end

    context 'with the grid not existing' do
      let(:path) { api_v3_paths.grid(5) }

      it 'responds with 404 NOT FOUND' do
        expect(subject.status).to eql 404
      end
    end

    context 'without the manage_boards permission' do
      let(:stored_grids) do
        view_boards_grid
      end

      let(:path) { api_v3_paths.grid(view_boards_grid.id) }

      it 'responds with 404 NOT FOUND' do
        expect(subject.status).to eql 404
      end
    end
  end

  describe '#post' do
    let(:path) { api_v3_paths.grids }

    let(:params) do
      {
        "rowCount": 10,
        "columnCount": 15,
        "widgets": [{
          "identifier": "work_package_query",
          "startRow": 4,
          "endRow": 8,
          "startColumn": 2,
          "endColumn": 5
        }],
        "_links": {
          "scope": {
            "href": project_boards_path(manage_boards_project)
          }
        }
      }.with_indifferent_access
    end

    before do
      post path, params.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'responds with 201 CREATED' do
      expect(subject.status).to eq(201)
    end

    it 'returns the created grid block' do
      expect(subject.body)
        .to be_json_eql('Grid'.to_json)
        .at_path('_type')
      expect(subject.body)
        .to be_json_eql(params['rowCount'].to_json)
        .at_path('rowCount')
      expect(subject.body)
        .to be_json_eql(params['widgets'][0]['identifier'].to_json)
        .at_path('widgets/0/identifier')
    end

    it 'persists the grid' do
      expect(Grids::Grid.count)
        .to eql(1)
    end

    context 'with invalid params' do
      let(:params) do
        {
          "rowCount": -5,
          "columnCount": "sdjfksdfsdfdsf",
          "widgets": [{
            "identifier": "work_package_query",
            "startRow": 4,
            "endRow": 8,
            "startColumn": 2,
            "endColumn": 5
          }],
          "_links": {
            "scope": {
              "href": project_boards_path(manage_boards_project)
            }
          }
        }.with_indifferent_access
      end

      it 'responds with 422' do
        expect(subject.status).to eq(422)
      end

      it 'does not create a grid' do
        expect(Grids::Grid.count)
          .to eql(0)
      end

      it 'returns the errors' do
        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("Widgets is outside of the grid.".to_json)
          .at_path('_embedded/errors/0/message')

        expect(subject.body)
          .to be_json_eql("Number of rows must be greater than 0.".to_json)
          .at_path('_embedded/errors/1/message')

        expect(subject.body)
          .to be_json_eql("Number of columns must be greater than 0.".to_json)
          .at_path('_embedded/errors/2/message')
      end
    end

    context 'without a scope link' do
      let(:params) do
        {
          "rowCount": 5,
          "columnCount": 5,
          "widgets": [{
            "identifier": "work_package_query",
            "startRow": 2,
            "endRow": 4,
            "startColumn": 2,
            "endColumn": 5
          }]
        }.with_indifferent_access
      end

      it 'responds with 422' do
        expect(subject.status).to eq(422)
      end

      it 'does not create a grid' do
        expect(Grids::Grid.count)
          .to eql(0)
      end

      it 'returns the errors' do
        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path('message')
      end
    end

    context 'without the permission to create boards in the project' do
      let(:params) do
        {
          "rowCount": 5,
          "columnCount": 5,
          "widgets": [{
            "identifier": "work_package_query",
            "startRow": 2,
            "endRow": 4,
            "startColumn": 2,
            "endColumn": 5
          }],
          "_links": {
            "scope": {
              "href": project_boards_path(view_boards_project)
            }
          }
        }.with_indifferent_access
      end

      it 'responds with 422' do
        expect(subject.status).to eq(422)
      end

      it 'does not create a grid' do
        expect(Grids::Grid.count)
          .to eql(0)
      end

      it 'returns the errors' do
        expect(subject.body)
          .to be_json_eql('Error'.to_json)
          .at_path('_type')

        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path('message')
      end
    end
  end
end
