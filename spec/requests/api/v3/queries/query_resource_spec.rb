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

RSpec.describe "API v3 Query resource",
               content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { create(:project, identifier: "test_project", public: false) }
  let(:other_project) { create(:project) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_work_packages] }
  let(:manage_public_queries_role) do
    create(:project_role, permissions: [:manage_public_queries])
  end
  let(:query) { create(:public_query, project:) }
  let(:other_query) { create(:public_query, project: other_project) }
  let(:global_query) { create(:global_query) }
  let(:work_package) { create(:work_package, project:) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe "#get queries/" do
    let(:path) { api_v3_paths.queries }
    let(:prepare) {}

    before do
      prepare

      get path
    end

    context "user has view_work_packages in a project" do
      it "succeeds" do
        expect(last_response).to have_http_status(:ok)
      end
    end

    context "user has manage_public_queries in a project" do
      let(:permissions) { [:manage_public_queries] }

      it "succeeds" do
        expect(last_response).to have_http_status(:ok)
      end
    end

    context "user not allowed to see queries" do
      let(:current_user) { create(:user) }
      let(:non_member_permissions) { [:view_work_packages] }

      let(:prepare) do
        # Create a public project so that the non-member permission has something to attach to
        create(:project, public: true, active: true)
      end

      include_context "with non-member permissions from non_member_permissions"

      it "succeeds" do
        expect(last_response).to have_http_status(:ok)
      end

      context "that is not allowed to see queries anywhere" do
        let(:non_member_permissions) { [] }

        it_behaves_like "unauthorized access"
      end
    end

    context "filtering for project" do
      let(:path) do
        filter = [project: { operator: "=", values: [project.id.to_s] }]

        api_v3_paths.path_for(:queries, filters: filter)
      end

      let(:prepare) do
        query
        global_query
        other_query

        create(:member,
               roles: [role],
               project: other_query.project,
               user: current_user)
      end

      it "includes only queries from the specified project" do
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("count")
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("total")
        expect(last_response.body)
          .to be_json_eql(query.name.to_json)
          .at_path("_embedded/elements/0/name")
      end
    end

    context "filtering for global query" do
      let(:path) do
        filter = [project: { operator: "!*", values: [] }]

        api_v3_paths.path_for(:queries, filters: filter)
      end

      let(:prepare) do
        query
        global_query
        other_query

        create(:member,
               roles: [role],
               project: other_query.project,
               user: current_user)
      end

      it "includes only queries not belonging to a project" do
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("count")
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("total")
        expect(last_response.body)
          .to be_json_eql(global_query.name.to_json)
          .at_path("_embedded/elements/0/name")
      end
    end

    context "filtering by updated_at" do
      let(:old_query) { create(:public_query, project:) }

      let(:prepare) do
        query
        old_query.update_column(:updated_at, DateTime.current - 4.hours)
      end

      let(:path) do
        filter = [updated_at: { operator: "<>d", values: [(DateTime.current - 3.hours).to_s] }]

        api_v3_paths.path_for(:queries, filters: filter)
      end

      it "includes only queries updated after the value" do
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("count")
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("total")
        expect(last_response.body)
          .to be_json_eql(query.name.to_json)
          .at_path("_embedded/elements/0/name")
      end
    end

    context "filtering by id" do
      let(:prepare) do
        query
        global_query
      end

      let(:path) do
        filter = [id: { operator: "=", values: [global_query.id.to_s] }]

        api_v3_paths.path_for(:queries, filters: filter)
      end

      it "includes only queries with that id" do
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("count")
        expect(last_response.body)
          .to be_json_eql(1)
          .at_path("total")
        expect(last_response.body)
          .to be_json_eql(global_query.name.to_json)
          .at_path("_embedded/elements/0/name")
      end
    end
  end

  describe "#get queries/:id" do
    let(:base_path) { api_v3_paths.query(query.id) }

    it_behaves_like "GET individual query" do
      context "lacking permissions" do
        let(:permissions) { [] }

        it_behaves_like "not found"
      end
    end
  end

  describe "#get queries/default" do
    let(:base_path) { api_v3_paths.query_default }

    it_behaves_like "GET individual query" do
      context "lacking permissions" do
        let(:permissions) { [] }

        it_behaves_like "unauthorized access"
      end
    end
  end

  describe "#delete queries/:id" do
    let(:path) { api_v3_paths.query query.id }
    let(:permissions) { %i[view_work_packages manage_public_queries] }

    before do
      delete path
    end

    it "responds with HTTP No Content" do
      expect(last_response).to have_http_status :no_content
    end

    it "deletes the Query" do
      expect(Query.exists?(query.id)).to be_falsey
    end

    context "user not allowed" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "unauthorized access"

      it "does not delete the Query" do
        expect(Query.exists?(query.id)).to be_truthy
      end
    end

    context "for a non-existent query" do
      let(:query_id) { 1337 } # could be anything as long as we do not create an actual query
      let(:path) { api_v3_paths.query query_id }

      it_behaves_like "not found"
    end
  end

  describe "#get queries/available_projects" do
    before do
      other_project
      get api_v3_paths.query_available_projects
    end

    it "succeeds" do
      expect(last_response).to have_http_status(:ok)
    end

    it "returns a Collection of projects for which the user has view work packages permission" do
      expect(last_response.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")
      expect(last_response.body)
        .to be_json_eql(1.to_json)
        .at_path("count")
      expect(last_response.body)
        .to be_json_eql(1.to_json)
        .at_path("total")
      expect(last_response.body)
        .to be_json_eql(api_v3_paths.project(project.id).to_json)
        .at_path("_embedded/elements/0/_links/self/href")
    end

    context "user not allowed" do
      let(:permissions) { [] }

      it_behaves_like "unauthorized access"
    end
  end

  describe "#star" do
    let(:star_path) { api_v3_paths.query_star query.id }

    before do
      patch star_path
    end

    describe "public queries" do
      context "user with permission to manage public queries" do
        let(:permissions) { %i[view_work_packages manage_public_queries] }

        context "when starring an unstarred query" do
          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path("starred")
          end
        end

        context "when starring already starred query" do
          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path("starred")
          end
        end

        context "when trying to star nonexistent query" do
          let(:star_path) { api_v3_paths.query_star 999 }

          it_behaves_like "not found"
        end
      end

      context "user without permission to manage public queries" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "unauthorized access"
      end
    end

    describe "private queries" do
      context "user with permission to save queries" do
        let(:query) { create(:private_query, project:, user: current_user) }
        let(:permissions) { %i[view_work_packages save_queries] }

        context "starring his own query" do
          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to true' do
            expect(last_response.body).to be_json_eql(true).at_path("starred")
          end
        end

        context "trying to star somebody else's query" do
          let(:another_user) { create(:user) }
          let(:query) { create(:private_query, project:, user: another_user) }

          it_behaves_like "not found"
        end
      end

      context "user without permission to save queries" do
        let(:query) { create(:private_query, project:, user: current_user) }
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "unauthorized access"
      end
    end
  end

  describe "#unstar" do
    let(:unstar_path) { api_v3_paths.query_unstar query.id }

    describe "public queries" do
      let(:query) { create(:public_query, project:) }

      context "user with permission to manage public queries" do
        let(:permissions) { %i[view_work_packages manage_public_queries] }

        context "when unstarring a starred query" do
          let(:query) { create(:public_query, project:, starred: true) }

          before do
            patch unstar_path
          end

          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to false' do
            expect(last_response.body).to be_json_eql(false).at_path("starred")
          end
        end

        context "when unstarring an unstarred query" do
          before do
            patch unstar_path
          end

          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to false' do
            expect(last_response.body).to be_json_eql(false).at_path("starred")
          end
        end

        context "when trying to unstar nonexistent query" do
          let(:unstar_path) { api_v3_paths.query_unstar 999 }

          before do
            patch unstar_path
          end

          it_behaves_like "not found"
        end
      end

      context "user without permission to manage public queries" do
        let(:permissions) { [:view_work_packages] }

        before do
          patch unstar_path
        end

        it_behaves_like "unauthorized access"
      end
    end

    describe "private queries" do
      context "user with permission to save queries" do
        let(:query) { create(:private_query, project:, user: current_user) }
        let(:permissions) { %i[view_work_packages save_queries] }

        before do
          patch unstar_path
        end

        context "unstarring his own query" do
          it "responds with 200" do
            expect(last_response).to have_http_status(:ok)
          end

          it 'returns the query with "starred" property set to true' do
            expect(last_response.body).to be_json_eql(false).at_path("starred")
          end
        end

        context "trying to unstar somebody else's query" do
          let(:another_user) { create(:user) }
          let(:query) { create(:private_query, project:, user: another_user) }

          it_behaves_like "not found"
        end
      end

      context "user without permission to save queries" do
        let(:query) { create(:private_query, project:, user: current_user) }
        let(:permissions) { [:view_work_packages] }

        before do
          patch unstar_path
        end

        it_behaves_like "unauthorized access"
      end
    end
  end

  describe "#post queries/form" do
    let(:path) { api_v3_paths.create_query_form }

    before do
      post path
    end

    it "succeeds" do
      expect(last_response).to have_http_status(:ok)
    end

    it "returns the form" do
      expect(last_response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end
  end
end
