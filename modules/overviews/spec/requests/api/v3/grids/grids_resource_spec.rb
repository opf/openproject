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

RSpec.describe "API v3 Grids resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  current_user do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[] }
  let(:project) { create(:project) }
  let(:grid) do
    create(:overview,
           project:,
           widgets:)
  end
  let(:widgets) do
    [create(:grid_widget,
            identifier: "custom_text",
            start_column: 1,
            end_column: 3,
            start_row: 1,
            end_row: 3,
            options: {
              text: custom_text
            })]
  end
  let(:custom_text) { "Some text a user wrote" }

  subject(:response) { last_response }

  describe "#get api/v3/grids/:id" do
    let(:path) { api_v3_paths.grid(grid.id) }

    before do
      grid

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

    it "identifies the url the grid is stored for" do
      expect(subject.body)
        .to be_json_eql(project_overview_path(project).to_json)
        .at_path("_links/scope/href")
    end

    it "has a widget that renders custom text" do
      expect(subject.body)
        .to be_json_eql("custom_text".to_json)
        .at_path("widgets/0/identifier")

      expect(subject.body)
        .to be_json_eql(custom_text.to_json)
        .at_path("widgets/0/options/text/raw")
    end

    context "with the grid not existing" do
      let(:path) { api_v3_paths.grid(grid.id + 1) }

      it "responds with 404 NOT FOUND" do
        expect(subject.status).to be 404
      end
    end
  end

  shared_examples_for "creates a grid resource" do
    it "responds with 201 CREATED" do
      expect(subject.status).to eq(201)
    end

    it "returns the created grid block" do
      expect(subject.body)
        .to be_json_eql("Grid".to_json)
              .at_path("_type")

      if params["rowCount"]
        expect(subject.body)
          .to be_json_eql(params["rowCount"].to_json)
                .at_path("rowCount")
      end
    end

    it "persists the grid" do
      expect(Grids::Grid.count)
        .to be(1)
    end
  end

  describe "#post api/v3/grids" do
    let(:path) { api_v3_paths.grids }

    let(:permissions) { %i[manage_overview] }

    let(:params) do
      {
        rowCount: 10,
        columnCount: 15,
        _links: {
          scope: {
            href: project_overview_path(project)
          }
        }
      }.with_indifferent_access
    end

    before do
      post path, params.to_json
    end

    it_behaves_like "creates a grid resource"

    context "if lacking the manage_overview permission and not changing the default values" do
      # Creating a grid should be possible for every member in the project to avoid having an empty page for the project
      # which is why this test case is the same as the one above.
      # But this is only true if only the scope is provided and no other attribute.
      let(:permissions) { %i[] }
      let(:params) do
        {
          _links: {
            scope: {
              href: project_overview_path(project)
            }
          }
        }.with_indifferent_access
      end

      it_behaves_like "creates a grid resource"
    end

    context "if lacking the manage_overview permission and changing the default values" do
      # Creating a grid should be possible for every member in the project to avoid having an empty page for the project
      # which is why this test case is the same as the one above.
      # But this is only true if only the scope is provided and no other attribute.
      # In this test, the rowCount and columnCount is changed
      let(:permissions) { %i[] }

      it "responds with 422" do
        expect(subject.status).to eq(422)
      end

      it "persists no grid" do
        expect(Grids::Grid.count)
          .to be(0)
      end
    end

    context "if not being a member in the project" do
      current_user do
        create(:user)
      end

      it "responds with 422" do
        expect(subject.status).to eq(422)
      end

      it "persists no grid" do
        expect(Grids::Grid.count)
          .to be(0)
      end
    end
  end
end
