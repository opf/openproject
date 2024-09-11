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

RSpec.describe "API v3 capabilities resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  shared_let(:project) { create(:project) }
  shared_current_user do
    create(:user,
           member_with_permissions: { project => %i[manage_members] })
  end

  let(:role) do
    create(:project_role, permissions: %i[manage_members])
  end
  let(:global_role) do
    create(:global_role, permissions: %i[create_user manage_user])
  end
  let(:other_user) { create(:user) }
  let(:other_user_global_member) do
    create(:global_member,
           principal: other_user,
           roles: [global_role])
  end
  let(:other_user_member) do
    create(:member,
           principal: other_user,
           roles: [role],
           project:)
  end

  describe "GET api/v3/capabilities" do
    let(:setup) do
      other_user_global_member
      other_user_member
    end
    let(:filters) { nil }
    let(:path) { api_v3_paths.path_for(:capabilities, filters:, sort_by: [%i(id asc)]) }

    before do
      setup

      get path
    end

    context "without params" do
      it "responds 400 Bad Request" do
        expect(subject.status).to eq(400)
      end

      it "communicates that either a context or a principal filter is required" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
          .at_path("errorIdentifier")
      end
    end

    context "when filtering by principal id (with a user)" do
      let(:filters) do
        [{ "principalId" => {
          "operator" => "=",
          "values" => [current_user.id.to_s]
        } }]
      end

      it "contains only the filtered capabilities in the response" do
        expect(subject.body)
          .to be_json_eql("4")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.user(current_user.id).to_json)
          .at_path("_embedded/elements/0/_links/principal/href")
      end
    end

    context "with pageSize, offset and sortBy and filter" do
      def expect_self_link(link, overrides = {})
        href = JSON.parse(subject.body).dig("_links", link, "href").split("?")
        expected_path_params = Rack::Utils.parse_nested_query(path.split("?").last)

        expect(href.first)
          .to eql(api_v3_paths.capabilities)

        expect(Rack::Utils.parse_nested_query(href.last))
          .to eql(expected_path_params.merge(overrides))
      end

      let(:filters) do
        [{ "principal" => {
          "operator" => "=",
          "values" => [other_user.id.to_s]
        } }]
      end
      let(:path) do
        api_v3_paths.path_for(:capabilities,
                              filters:,
                              sort_by: [%i(id asc)],
                              select: "*,elements/*",
                              page_size: 2,
                              offset: 3)
      end

      it "returns a slice of the visible memberships" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("7")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("2")
          .at_path("count")

        expect(subject.body)
          .to be_json_eql("users/create/g-#{other_user.id}".to_json)
          .at_path("_embedded/elements/0/id")
      end

      it "includes links for self and jumping" do
        expect_self_link("self")
        expect_self_link("jumpTo", "offset" => "{offset}")
        expect_self_link("changeSize", "pageSize" => "{size}")
        expect_self_link("previousByOffset", "offset" => "2")
        expect_self_link("nextByOffset", "offset" => "4")
      end
    end

    context "when filtering by principal id (group)" do
      let(:filters) do
        [{ "principalId" => {
          "operator" => "=",
          "values" => [group.id.to_s]
        } }]
      end
      let(:other_user) { group }
      let(:group) { create(:group) }

      let(:setup) do
        other_user_member
      end

      it "returns a collection of capabilities" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("4")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("activities/read/p#{project.id}-#{other_user.id}".to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "when filtering by principal id (placeholder user)" do
      let(:filters) do
        [{ "principalId" => {
          "operator" => "=",
          "values" => [placeholder_user.id.to_s]
        } }]
      end
      let(:other_user) { placeholder_user }
      let(:placeholder_user) do
        create(:placeholder_user)
      end

      let(:setup) do
        other_user_member
      end

      it "returns a collection of capabilities" do
        expect(subject.body)
          .to be_json_eql("Collection".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("4")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("activities/read/p#{project.id}-#{other_user.id}".to_json)
          .at_path("_embedded/elements/0/id")
      end
    end

    context "when filtering by principal id (with a user) but with the not operator" do
      let(:filters) do
        [{ "principalId" => {
          "operator" => "!",
          "values" => [current_user.id.to_s]
        } }]
      end

      it "responds 400 Bad Request" do
        expect(subject.status).to eq(400)
      end

      it "communicates that either a context or a principal filter is required" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
          .at_path("errorIdentifier")
      end
    end

    context "with an invalid filter" do
      let(:filters) do
        [{ "bogus" => {
          "operator" => "=",
          "values" => [current_user.id.to_s]
        } }]
      end

      it "returns 422" do
        expect(subject.status)
          .to be 422
      end

      it "communicates the error message" do
        expect(subject.body)
          .to be_json_eql("Error".to_json)
          .at_path("_type")

        expect(subject.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:MultipleErrors".to_json)
          .at_path("errorIdentifier")
      end
    end

    context "when filtering by project context" do
      let(:other_project) { create(:project) }
      let(:other_user_other_member) do
        create(:member,
               principal: other_user,
               roles: [role],
               project: other_project)
      end

      let(:filters) do
        [{ "context" => {
          "operator" => "=",
          "values" => ["p#{other_project.id}"]
        } }]
      end

      let(:setup) do
        other_user_global_member
        other_user_member
        other_user_other_member
      end

      it "contains only the filtered capabilities in the response" do
        expect(subject.body)
          .to be_json_eql("4")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.project(other_project.id).to_json)
          .at_path("_embedded/elements/0/_links/context/href")
      end
    end

    context "when filtering by global context" do
      let(:filters) do
        [{ "context" => {
          "operator" => "=",
          "values" => ["g"]
        } }]
      end

      it "contains only the filtered capabilities in the response" do
        expect(subject.body)
          .to be_json_eql("3")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql(api_v3_paths.capabilities_contexts_global.to_json)
          .at_path("_embedded/elements/0/_links/context/href")
      end
    end

    context "when signaling to only include a subset of properties" do
      let(:path) { api_v3_paths.path_for(:capabilities, filters:, sort_by: [%i(id asc)], select: "elements/id") }

      let(:filters) do
        [{ "principalId" => {
          "operator" => "=",
          "values" => [current_user.id.to_s]
        } }]
      end

      it "contains only the filtered capabilities in the response" do
        expected = {
          _embedded: {
            elements: [
              {
                id: "activities/read/p#{project.id}-#{current_user.id}"
              },
              {
                id: "memberships/create/p#{project.id}-#{current_user.id}"
              },
              {
                id: "memberships/destroy/p#{project.id}-#{current_user.id}"
              },
              {
                id: "memberships/update/p#{project.id}-#{current_user.id}"
              }
            ]
          }
        }

        expect(subject.body)
          .to be_json_eql(expected.to_json)
      end
    end

    context "without permissions" do
      current_user do
        create(:user)
      end

      let(:filters) do
        [{ "context" => {
          "operator" => "=",
          "values" => ["g"]
        } }]
      end

      it "is empty and includes an empty element set", :aggregate_failures do
        expect(subject.body)
          .to be_json_eql("0")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql([].to_json)
                .at_path("_embedded/elements")
      end
    end

    context "when filtering by action" do
      let(:filters) do
        [{ "action" => {
          "operator" => "=",
          "values" => ["memberships/create"]
        } },
         { "principalId" => {
           "operator" => "=",
           "values" => [other_user.id.to_s]
         } }]
      end

      let(:setup) do
        other_user_member
      end

      it "contains only the filtered capabilities in the response" do
        expect(subject.body)
          .to be_json_eql("1")
          .at_path("total")

        expect(subject.body)
          .to be_json_eql("memberships/create/p#{project.id}-#{other_user.id}".to_json)
          .at_path("_embedded/elements/0/id")
      end
    end
  end

  describe "GET /api/v3/capabilities/:id" do
    let(:path) { api_v3_paths.capability("memberships/create/p#{project.id}-#{other_user.id}") }

    let(:setup) do
      other_user_member
    end

    before do
      setup

      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the capability" do
      expect(subject.body)
        .to be_json_eql("Capability".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql("memberships/create/p#{project.id}-#{other_user.id}".to_json)
        .at_path("id")
    end

    context "if querying a non existing capability" do
      let(:path) { api_v3_paths.capability("foo/bar/p#{project.id}-#{other_user.id}") }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be 404
      end
    end

    context "if querying with malformed id" do
      let(:path) { api_v3_paths.capability("foo/bar/baz-5") }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be 404
      end
    end

    context "if querying for an invisible user" do
      current_user do
        create(:user)
      end

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be 404
      end
    end
  end
end
