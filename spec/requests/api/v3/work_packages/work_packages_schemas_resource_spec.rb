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

RSpec.describe API::V3::WorkPackages::Schema::WorkPackageSchemasAPI do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project) }
  let(:type) { create(:type) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  describe "GET /api/v3/work_packages/schemas/filters=..." do
    let(:filter_values) { ["#{project.id}-#{type.id}"] }
    let(:schema_path) do
      filter = [{ "id" => {
        "operator" => "=",
        "values" => filter_values
      } }]

      "#{api_v3_paths.work_package_schemas}?#{{ filters: filter.to_json }.to_query}"
    end

    before do
      allow(User).to receive(:current).and_return(current_user)
      get schema_path
    end

    context "authorized" do
      context "valid" do
        it "returns HTTP 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "returns a collection of schemas" do
          expect(last_response.body)
            .to be_json_eql(api_v3_paths.work_package_schema(project.id, type.id).to_json)
            .at_path("_embedded/elements/0/_links/self/href")
        end

        it "has the self href set correctly" do
          expect(last_response.body)
            .to be_json_eql(schema_path.to_json)
            .at_path("_links/self/href")
        end
      end

      context "for a non existing project" do
        let(:filter_values) { ["#{0}-#{type.id}"] }

        it "returns HTTP 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "returns an empty collection" do
          expect(last_response.body)
            .to be_json_eql(0.to_json)
            .at_path("count")
        end
      end

      context "for a non existing type" do
        let(:filter_values) { ["#{project.id}-#{0}"] }

        it "returns HTTP 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "returns an empty collection" do
          expect(last_response.body)
            .to be_json_eql(0.to_json)
            .at_path("count")
        end
      end

      context "for a non valid filter" do
        let(:filter_values) { ["bogus"] }

        it "returns HTTP 400" do
          expect(last_response).to have_http_status(:bad_request)
        end

        it "returns an error" do
          expect(last_response.body)
            .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
            .at_path("errorIdentifier")
        end
      end
    end

    context "not authorized" do
      let(:role) { create(:project_role, permissions: []) }

      it "returns HTTP 403" do
        expect(last_response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v3/work_packages/schemas/:id" do
    let(:schema_path) { api_v3_paths.work_package_schema project.id, type.id }

    context "logged in" do
      before do
        allow(User).to receive(:current).and_return(current_user)
        get schema_path
      end

      context "valid schema" do
        it "returns HTTP 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "sets a weak ETag" do
          expect(last_response.headers["ETag"]).to match(/W\/"\w+"/)
        end

        it "caches the response" do
          schema_class = API::V3::WorkPackages::Schema::TypedWorkPackageSchema
          representer_class = API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter

          schema = schema_class.new(project:,
                                    type:)
          self_link = api_v3_paths.work_package_schema(project.id, type.id)
          represented_schema = representer_class.create(schema,
                                                        self_link:,
                                                        current_user:)

          expect(OpenProject::Cache.fetch(represented_schema.json_cache_key)).not_to be_nil
        end
      end

      context "id is too long" do
        it_behaves_like "not found" do
          let(:schema_path) { "#{api_v3_paths.work_package_schema project.id, type.id}-1" }
        end
      end

      context "id is too short" do
        it_behaves_like "not found" do
          let(:schema_path) { "/api/v3/work_packages/schemas/#{project.id}" }
        end
      end
    end

    context "not logged in" do
      before do
        get schema_path
      end

      it_behaves_like "not found response based on login_required"
    end
  end

  describe "GET /api/v3/work_packages/schemas/sums" do
    let(:schema_path) { api_v3_paths.work_package_sums_schema }

    subject { last_response }

    context "logged in" do
      before do
        allow(User).to receive(:current).and_return(current_user)
        get schema_path
      end

      context "valid schema" do
        it "returns HTTP 200" do
          expect(last_response).to have_http_status(:ok)
        end

        # Further fields are tested in the representer specs
        it "returns the schema for estimated_hours" do
          expected = { type: "Duration",
                       name: "Work",
                       required: false,
                       hasDefault: false,
                       writable: false,
                       options: {} }
          expect(subject.body).to be_json_eql(expected.to_json).at_path("estimatedTime")
        end
      end
    end

    context "when not logged in" do
      before do
        get schema_path
      end

      it_behaves_like "not found response based on login_required"
    end
  end
end
