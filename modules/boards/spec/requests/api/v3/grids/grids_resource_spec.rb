#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Grids resource for Board Grids", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:manage_board_views_project) { create(:project) }
  shared_let(:show_board_views_project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:show_board_views_role) { create(:project_role, permissions: [:show_board_views]) }
  shared_let(:manage_board_views_role) { create(:project_role, permissions: [:manage_board_views]) }
  shared_let(:other_role) { create(:project_role, permissions: []) }
  shared_let(:current_user) do
    create(:user).tap do |user|
      create(:member, user:, project: manage_board_views_project, roles: [manage_board_views_role])
      create(:member, user:, project: show_board_views_project, roles: [show_board_views_role])
      create(:member, user:, project: other_project, roles: [other_role])
    end
  end

  let(:manage_board_views_grid) do
    create(:board_grid, project: manage_board_views_project)
  end
  let(:show_board_views_grid) do
    create(:board_grid, project: show_board_views_project)
  end
  let(:other_board_grid) do
    create(:board_grid, project: other_project)
  end

  before do
    login_as(current_user)
  end

  subject(:response) { last_response }

  describe "#get INDEX" do
    let(:path) { api_v3_paths.grids }

    let(:stored_grids) do
      manage_board_views_grid
      other_board_grid
    end

    before do
      stored_grids

      get path
    end

    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "sends a collection of grids but only those visible to the current user" do
      expect(subject.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql("Grid".to_json)
        .at_path("_embedded/elements/0/_type")

      expect(subject.body)
        .to be_json_eql(1.to_json)
        .at_path("total")
    end

    context "with a filter on the scope attribute for all boards of a project" do
      # The user would be able to see both boards
      shared_let(:other_role) { create(:project_role, permissions: [:show_board_views]) }

      let(:path) do
        filter = [{ "scope" =>
                      {
                        "operator" => "=",
                        "values" => [project_work_package_boards_path(manage_board_views_project)]
                      } }]

        "#{api_v3_paths.grids}?#{{ filters: filter.to_json }.to_query}"
      end

      it "responds with 200 OK" do
        expect(subject.status).to eq(200)
      end

      it "sends only the board of the project" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("Grid".to_json)
          .at_path("_embedded/elements/0/_type")

        expect(subject.body)
          .to be_json_eql(1.to_json)
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(manage_board_views_grid.id.to_json)
          .at_path("_embedded/elements/0/id")
      end
    end
  end

  describe "#get" do
    let(:path) { api_v3_paths.grid(manage_board_views_grid.id) }

    let(:stored_grids) do
      manage_board_views_grid
    end

    before do
      stored_grids

      get path
    end

    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "sends a grid block" do
      expect(subject.body)
        .to be_json_eql("Grid".to_json)
        .at_path("_type")
    end

    it "has a name" do
      expect(subject.body)
        .to be_json_eql("My board".to_json)
        .at_path("name")
    end

    it "identifies the url the grid is stored for" do
      expect(subject.body)
        .to be_json_eql(project_work_package_boards_path(manage_board_views_project).to_json)
        .at_path("_links/scope/href")
    end

    context "with the scope not existing" do
      let(:stored_grids) do
      end

      let(:path) { api_v3_paths.grid(5) }

      it "responds with 404 NOT FOUND" do
        expect(subject.status).to be 404
      end
    end

    context "when lacking permission to see the grid" do
      let(:stored_grids) do
        other_board_grid
      end

      let(:path) { api_v3_paths.grid(other_board_grid.id) }

      it "responds with 404 NOT FOUND" do
        expect(subject.status).to be 404
      end
    end
  end

  describe "#patch" do
    let(:path) { api_v3_paths.grid(manage_board_views_grid.id) }

    let(:params) do
      {
        rowCount: 10,
        columnCount: 15,
        widgets: [{
          identifier: "work_package_query",
          startRow: 4,
          endRow: 8,
          startColumn: 2,
          endColumn: 5
        }]
      }.with_indifferent_access
    end

    let(:stored_grids) do
      manage_board_views_grid
    end

    before do
      stored_grids

      patch path, params.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "responds with 200 OK" do
      expect(subject.status).to eq(200)
    end

    it "returns the altered grid block" do
      expect(subject.body)
        .to be_json_eql("Grid".to_json)
        .at_path("_type")
      expect(subject.body)
        .to be_json_eql(params["rowCount"].to_json)
        .at_path("rowCount")
      expect(subject.body)
        .to be_json_eql(params["widgets"][0]["identifier"].to_json)
        .at_path("widgets/0/identifier")
    end

    it "perists the changes" do
      expect(manage_board_views_grid.reload.row_count)
        .to eql params["rowCount"]
    end

    context "with invalid params" do
      let(:params) do
        {
          rowCount: -5,
          columnCount: 15,
          widgets: [{
            identifier: "work_package_query",
            startRow: 4,
            endRow: 8,
            startColumn: 2,
            endColumn: 5
          }]
        }.with_indifferent_access
      end

      it "responds with 422 and mentions the error" do
        expect(subject.status).to eq 422

        expect(JSON.parse(subject.body)["_embedded"]["errors"].map { |e| e["message"] })
          .to contain_exactly("Widgets is outside of the grid.", "Number of rows must be greater than 0.")
      end

      it "does not persist the changes to widgets" do
        expect(manage_board_views_grid.reload.widgets.count)
          .to eql OpenProject::Boards::GridRegistration.defaults[:widgets].size
      end
    end

    context "with a scope param" do
      let(:params) do
        {
          _links: {
            scope: {
              href: ""
            }
          }
        }.with_indifferent_access
      end

      it_behaves_like "read-only violation", "scope", Boards::Grid
    end

    context "with the grid not existing" do
      let(:path) { api_v3_paths.grid(1234) }

      it "responds with 404 NOT FOUND" do
        expect(subject.status).to be 404
      end
    end

    context "without the manage_board_views permission" do
      let(:stored_grids) do
        show_board_views_grid
      end

      let(:path) { api_v3_paths.grid(show_board_views_grid.id) }

      it "responds with 404 NOT FOUND" do
        expect(subject.status).to be 404
      end
    end
  end

  describe "#post" do
    let(:path) { api_v3_paths.grids }

    let(:params) do
      {
        rowCount: 10,
        name: "foo",
        columnCount: 15,
        widgets: [{
          identifier: "work_package_query",
          startRow: 4,
          endRow: 8,
          startColumn: 2,
          endColumn: 5
        }],
        _links: {
          scope: {
            href: project_work_package_boards_path(manage_board_views_project)
          }
        }
      }.with_indifferent_access
    end

    before do
      post path, params.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "responds with 201 CREATED" do
      expect(subject.status).to eq(201)
    end

    it "returns the created grid block" do
      expect(subject.body)
        .to be_json_eql("Grid".to_json)
        .at_path("_type")
      expect(subject.body)
        .to be_json_eql("foo".to_json)
        .at_path("name")
      expect(subject.body)
        .to be_json_eql(params["rowCount"].to_json)
        .at_path("rowCount")
      expect(subject.body)
        .to be_json_eql(params["widgets"][0]["identifier"].to_json)
        .at_path("widgets/0/identifier")
    end

    it "persists the grid" do
      expect(Grids::Grid.count)
        .to be(1)
    end

    context "with invalid params" do
      let(:params) do
        {
          name: "foo",
          rowCount: -5,
          columnCount: "sdjfksdfsdfdsf",
          widgets: [{
            identifier: "work_package_query",
            startRow: 4,
            endRow: 8,
            startColumn: 2,
            endColumn: 5
          }],
          _links: {
            scope: {
              href: project_work_package_boards_path(manage_board_views_project)
            }
          }
        }.with_indifferent_access
      end

      it "responds with 422" do
        expect(subject.status).to eq(422)
      end

      it "does not create a grid" do
        expect(Grids::Grid.count)
          .to be(0)
      end

      it "returns the errors" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(JSON.parse(subject.body)["_embedded"]["errors"].map { |e| e["message"] })
          .to contain_exactly("Widgets is outside of the grid.", "Number of rows must be greater than 0.",
                              "Number of columns must be greater than 0.")
      end
    end

    context "without a scope link" do
      let(:params) do
        {
          rowCount: 5,
          name: "foo",
          columnCount: 5,
          widgets: [{
            identifier: "work_package_query",
            startRow: 2,
            endRow: 4,
            startColumn: 2,
            endColumn: 5
          }]
        }.with_indifferent_access
      end

      it "responds with 422" do
        expect(subject.status).to eq(422)
      end

      it "does not create a grid" do
        expect(Grids::Grid.count)
          .to be(0)
      end

      it "returns the errors" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path("message")
      end
    end

    context "without the permission to create boards in the project" do
      let(:params) do
        {
          name: "foo",
          rowCount: 5,
          columnCount: 5,
          widgets: [{
            identifier: "work_package_query",
            startRow: 2,
            endRow: 4,
            startColumn: 2,
            endColumn: 5
          }],
          _links: {
            scope: {
              href: project_work_package_boards_path(show_board_views_project)
            }
          }
        }.with_indifferent_access
      end

      it "responds with 422" do
        expect(subject.status).to eq(422)
      end

      it "does not create a grid" do
        expect(Grids::Grid.count)
          .to be(0)
      end

      it "returns the errors" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path("message")
      end
    end
  end
end
