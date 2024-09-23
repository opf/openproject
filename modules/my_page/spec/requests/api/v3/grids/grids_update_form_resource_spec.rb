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

RSpec.describe "PATCH /api/v3/grids/:id/form", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:current_user) do
    create(:user)
  end

  let(:grid) do
    create(:my_page, user: current_user)
  end
  let(:path) { api_v3_paths.grid_form(grid.id) }
  let(:params) { {} }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "#post" do
    before do
      post path, params.to_json, "CONTENT_TYPE" => "application/json"
    end

    let(:expected_payload) do
      {
        rowCount: 7,
        columnCount: 4,
        options: {},
        widgets: [
          {
            _type: "GridWidget",
            identifier: "news",
            options: {},
            startRow: 1,
            endRow: 7,
            startColumn: 1,
            endColumn: 3
          },
          {
            _type: "GridWidget",
            identifier: "documents",
            options: {},
            startRow: 1,
            endRow: 7,
            startColumn: 3,
            endColumn: 5
          }
        ],
        _links: {
          attachments: [],
          scope: {
            href: "/my/page",
            type: "text/html"
          }
        }
      }
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be 200
    end

    it "is of type form" do
      expect(subject.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "contains a Schema disallowing setting scope" do
      expect(subject.body)
        .to be_json_eql("Schema".to_json)
        .at_path("_embedded/schema/_type")

      expect(subject.body)
        .to be_json_eql(false.to_json)
        .at_path("_embedded/schema/scope/writable")
    end

    it "contains the current data in the payload" do
      expect(subject.body)
        .to be_json_eql(expected_payload.to_json)
        .at_path("_embedded/payload")
    end

    it "has a commit link" do
      expect(subject.body)
        .to be_json_eql(api_v3_paths.grid(grid.id).to_json)
        .at_path("_links/commit/href")
    end

    context "with some value for the scope value" do
      let(:params) do
        {
          _links: {
            scope: {
              href: "/some/path"
            }
          }
        }
      end

      it "has a validation error on scope as the value is not writable" do
        expect(subject.body)
          .to be_json_eql("Scope was attempted to be written but is not writable.".to_json)
          .at_path("_embedded/validationErrors/scope/message")
      end
    end

    context "with an unsupported widget identifier" do
      let(:params) do
        {
          widgets: [
            {
              _type: "GridWidget",
              identifier: "bogus_identifier",
              startRow: 4,
              endRow: 5,
              startColumn: 1,
              endColumn: 2
            }
          ]
        }
      end

      it "has a validationError on widget" do
        expect(subject.body)
          .to be_json_eql("Widgets is not set to one of the allowed values.".to_json)
          .at_path("_embedded/validationErrors/widgets/message")
      end
    end

    context "for another user's grid" do
      let(:other_user) { create(:user) }
      let(:other_grid) { create(:my_page, user: other_user) }

      let(:path) { api_v3_paths.grid_form(other_grid.id) }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be 404
      end
    end
  end
end
